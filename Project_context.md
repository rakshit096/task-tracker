# Task Tracker — Full Project Context

A reference document for continuing this project, or rebuilding it from scratch with the same design decisions. Written after a multi-session build, covering everything implemented, why each decision was made, and what's still open.

---

## Tech stack

- **Ruby** 3.2.0, **Rails** 8.1.3.1
- **Database:** SQLite, via 4 logical databases (`primary`, `cache`, `queue`, `cable`) — required for Solid Queue/Cache/Cable
- **Frontend:** Server-rendered ERB + Tailwind CSS + Turbo (Hotwire). No SPA framework, no custom JavaScript.
- **Background jobs:** Solid Queue (DB-backed, no Redis)
- **Auth:** Rails 8's built-in cookie-session generator + custom opaque Bearer token for API
- **Testing:** Minitest (Rails default), fixtures for test data

---

## Data model

```
User
  ├── has_many :projects (owns)
  ├── has_many :assigned_tasks (via Task.assignee_id)
  ├── has_many :sessions
  ├── role: "user" | "admin" (default "user")
  └── api_token (has_secure_token, opaque, never expires)

Project
  ├── belongs_to :user (owner)
  ├── has_many :tasks, dependent: :destroy
  ├── name (unique scoped to user_id), description
  └── status: enum — planning(0) | in_progress(1) | completed(2) | on_hold(3), default planning
       — MANUALLY set by owner, NOT auto-derived from task completion (deliberate choice, see "Decisions" below)

Task
  ├── belongs_to :project
  ├── belongs_to :assignee, class_name: "User", optional: true
  ├── title, description
  └── status: enum — pending(0) | in_progress(1) | done(2), default pending
```

---

## Authentication

- Rails 8's `bin/rails generate authentication` — generated `User`, `Session`, `SessionsController`, `PasswordsController`, `Authentication` concern.
- **Cookie-session**: `Session` row in DB, signed cookie (`cookies.signed.permanent[:session_id]`) holds only the session ID — **never expires** (known gap, see below).
- **`Current`** (`ActiveSupport::CurrentAttributes`) holds `session` AND `user` as independent attributes (not derived via `delegate`) — this was a deliberate change made to support token auth, which has no `Session` record.
- **Password reset**: `generates_token_for :password_reset, expires_in: 15.minutes` — signed, expiring, tied to password salt so it invalidates after a password change.
- **Registration**: custom `RegistrationsController` (not part of the generator), logs the user in immediately via `start_new_session_for`.
- **Already-authenticated-user guard**: `SessionsController` and `RegistrationsController` both have `before_action :redirect_if_authenticated, only: %i[ new create ]` — fixes a real bug where browser back/forward could show the login form to an already-logged-in user.

### Token-based API auth
- `User#api_token` via `has_secure_token` — **opaque** token (random string looked up in DB), explicitly **not JWT** (no self-contained payload, no built-in expiry, revocation = regenerate).
- `Authentication#require_authentication` tries cookie session first, then `resume_session_by_token` (reads `Authorization: Bearer <token>` header, `User.find_by(api_token:)`), then redirects to login.
- `TasksController#index` (JSON only) returns `@tasks.as_json(only: [:id, :title, :description, :status, :assignee_id])` — scoped to the authenticated user's own projects.

---

## Authorization model (role-based, built incrementally)

**Core pattern used everywhere:** separate "find the record" from "is this allowed" once more than one legitimate access path exists.

### Roles
- `user.admin?` → `role == "admin"`. Global, site-wide — **not** per-project. Admin bypasses ownership checks everywhere via `|| Current.user.admin?`.

### ProjectsController
- `set_project`: `Current.user.admin? ? Project.find(id) : Current.user.projects.find(id)` — **scoped directly in the query**, no separate authorize filter needed, because for `Project` there is exactly ONE legitimate access rule (owner or admin) — no second path like a Task's assignee.
- `index`: admins see `Project.all`; regular users see only `Current.user.projects`.
- Delete permission: **owner can delete their own** OR **admin can delete any** (deliberate decision — "admin-only delete" was considered and rejected as too restrictive for a task tracker; see Decisions).

### TasksController
- `set_project`: **deliberately left UNSCOPED** (`Project.find(params[:project_id])`) — NOT a bug. A Task has a second legitimate viewer (the assignee, who doesn't own the project), so scoping the project lookup by ownership would break that case. Authorization is instead handled by explicit filters.
- `authorize_viewer!` (on `show`, `update_status`): passes if `@project.user == Current.user || @task.assignee == Current.user || Current.user.admin?`
- `authorize_project_owner!` (on `new create edit update destroy`): passes if `@project.user == Current.user || Current.user.admin?`
- **Permission matrix implemented:**

  | Role/relationship | View task | Edit title/desc | Update status | Delete |
  |---|---|---|---|---|
  | Admin | ✅ any | ✅ any | ✅ any | ✅ any |
  | Project owner | ✅ own | ✅ own | ✅ own | ✅ own |
  | Assignee (not owner) | ✅ assigned | ❌ | ✅ | ❌ |
  | Anyone else | ❌ | ❌ | ❌ | ❌ |

- `assigned_to_me` action: `Current.user.assigned_tasks.includes(:project)` — powers the "Assigned to Me" nav page. Views conditionally hide owner-only links (e.g. "Edit", "Back to project") when the viewer is the assignee, not the owner, since those destinations/actions aren't available to them.

### A real bug that was caught and fixed during this build
When refactoring `TasksController` for assignee access, `create`/`new` were initially left OUT of the owner-authorization filter list — meaning any logged-in user could create a task inside ANY project by guessing its ID in the URL. Caught by an existing authorization test (`test_cannot_create_a_task_in_another_user's_project`), which failed after the refactor. **Lesson embedded in the test suite now**: every action touching a project/task must be explicitly covered by an authorize filter — nothing is safe by default once `set_project` stopped being self-scoping.

---

## Turbo Streams (reactivity, no custom JS)

- Task status dropdown: `onchange: "this.form.requestSubmit()"` submits via Turbo automatically.
- `update_status.turbo_stream.erb`: `turbo_stream.replace dom_id(@task) { render "task", task: @task, project: @project }` — swaps just that task's `<li>` in place.
- Confirmed: `dom_id` targets the specific element, works correctly regardless of which parent list (`#unassigned_tasks` / `#assigned_tasks`) the task lives in.
- Full-page actions (editing title/desc/assignee) deliberately do NOT use Turbo Streams — they redirect and full-reload, which is fine because that's also how moving a task between Unassigned/Assigned sections "just happens" (no explicit move logic — the lists are just fresh DB queries on every page load, see below).

---

## Background jobs (Solid Queue)

- `Task#after_commit :notify_assignee, if: :saved_change_to_assignee_id?` → `TaskAssignmentNotifierJob.perform_later(self)` if assignee present.
- `TaskAssignmentNotifierJob#perform`: `TaskMailer.assigned(task).deliver_now` (uses `deliver_now` not `deliver_later` since already inside a job).
- **Multi-database setup was the trickiest part to get working**: `config/database.yml` needed explicit `primary/cache/queue/cable` split under `development` (only `production` had it by default from `rails new`). Also required in `config/environments/development.rb`:
  ```ruby
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  ```
- Run `bin/jobs` as a separate, persistent terminal process — it does NOT share a process with `bin/rails server`. Communication between web process and worker is entirely through DB rows (`solid_queue_jobs` table) — fully decoupled.

---

## Task separation (Unassigned / Assigned)

- `Task.scope :unassigned, -> { where(assignee_id: nil) }` / `scope :assigned, -> { where.not(assignee_id: nil) }`
- `ProjectsController#show`: `@unassigned_tasks = @project.tasks.unassigned`, `@assigned_tasks = @project.tasks.assigned.includes(:assignee)`
- View renders two separate sections. **No "move" logic exists anywhere** — tasks appear in the correct section purely because both lists are re-queried fresh from the DB on every page load. Assigning a task via the edit form → full page redirect → both lists recompute → task "moves" automatically.
- **Deliberately NOT built**: self-claiming of unassigned tasks by non-owners. Flagged as a natural next feature but intentionally out of scope — it opens a new permissions question (should any user be able to self-assign in a project they don't own?) that wasn't part of the original ask.

---

## Project status feature (in progress as of last session)

- **Decision made: Approach 2 (stored, manually-set status)**, not Approach 1 (computed from task completion). Rationale: owner wants manual control (e.g. `on_hold`), not purely mechanical state.
- **Known trade-off accepted**: manual status can drift from reality (all tasks done, but project still shows `in_progress`). Decided to mitigate with **Option B: a gentle UI nudge**, not Option A (ignore it) or Option C (auto-sync, which would silently reintroduce Approach 1's logic).
- **Nudge design (planned, not yet built as of last session):**
  - Logic belongs in a **model method** on `Project` (not inline in the view) — e.g. `all_tasks_done_but_not_marked_completed?`
  - Banner shown on `projects/show.html.erb` when true, with a one-click button that reuses the existing `update` action (form posting `project[status]=completed`) — no new route/action needed, unlike `Task#update_status` which needed Turbo-specific handling.
  - **Known accepted limitations**: heuristic only fires if the project HAS tasks and ALL are done (a project with zero tasks, or intentionally-abandoned pending tasks, won't trigger it). The reverse case (marking completed, then adding a new pending task later) is NOT handled — explicitly scoped out to avoid scope creep.
- **Status badge colors** (`ProjectsHelper#project_status_badge_class`): planning=gray, in_progress=blue, completed=green, on_hold=yellow. Hit a real debugging lesson here: `bg-yellow-100` was correctly applied in the DOM but Tailwind hadn't compiled CSS rules for it (watcher wasn't running / needed `bin/rails tailwindcss:build` to force a fresh compile) — classes existing in markup doesn't guarantee Tailwind generated the CSS for them.

---

## Known gaps / deliberately out of scope (good to mention proactively in a demo)

1. **Sessions and API tokens never expire.** No idle timeout, no absolute session length, no token rotation. Flagged repeatedly as a real production concern, intentionally deferred.
2. **No project membership concept.** Any registered user can be assigned to any task in any project — not scoped to "team members" of that project. Assignee dropdown in the task form lists `User.all`.
3. **N+1 query detection (Bullet gem) was introduced but the user chose to skip actually implementing fixes** — gem setup and diagnosis were covered conceptually, not applied to the codebase. Worth revisiting before "production-ready" claims.
4. **No rate limiting, no structured API error responses (`rescue_from`), no pagination, no explicit DB-level unique constraints (only model-level `validates uniqueness`, which is not race-condition-safe)** — all discussed as a "Tier 1" backend-maturity roadmap, not yet implemented.
5. **Self-claiming of unassigned tasks** — not built, deliberately (see Task separation section).
6. **Project status nudge banner** — designed but not yet coded as of the last session (see above) — this is the immediate next step if resuming.

---

## Testing status

- Model tests: `User`, `Project`, `Task` — validations, associations, enum defaults, uniqueness scoping, job-enqueue triggers on assignee change.
- Request tests: `ProjectsController`, `TasksController` — auth required, ownership scoping (including the caught `create` authorization gap), full CRUD, status updates, job side effects.
- `TaskMailerTest` fixed (was an unfilled generator stub).
- `PasswordsControllerTest#test_update` fixed (was sending a 3-character password, which newly-added length validation correctly rejected — test predated the validation).
- Admin-specific authorization tests were planned but not yet confirmed written as of the last session (add: admin can view/edit/delete another user's project/task; regular user still cannot).
- Task separation scopes (`unassigned`/`assigned`) — tests suggested but not yet confirmed added.

---

## Deployment

- Decided on **Render** (not Kamal+VPS) for the first deploy, prioritizing speed over deployment-mechanics depth. Kamal + a VPS (Hetzner/DigitalOcean) was discussed as the more "real backend practice" option and may be worth doing later as a separate exercise.
- Pre-deploy checklist started: confirm `config/master.key` is gitignored and available as an env var on Render, confirm `database.yml`'s `production` section (multi-DB split already present from the generator) matches Render's persistent disk setup, confirm a worker process config for `bin/jobs` separate from the web service.
- **Not yet completed** — this was paused to go do the RBAC/task-separation/project-status features instead.

---

## How to run locally

Three terminals, always:
```bash
bin/rails server              # web
bin/jobs                      # Solid Queue worker
bin/rails tailwindcss:watch   # CSS rebuild on change
```
(`bin/dev` works too if `foreman` is installed, but still needs `bin/jobs` separately.)

---

## Biggest reusable lessons from this build (good to remember for future projects)

1. **`private` in Ruby has no per-method scoping** — everything below it is private until the class ends or another visibility keyword appears. Caused two real bugs in this project (a controller action silently unreachable, a model method silently unreachable).
2. **Scope the query vs. use a separate authorize filter** — scope directly when there's exactly one legitimate access rule; use a separate filter when more than one legitimate path to the same record exists (owner vs. assignee).
3. **Don't use exception-driven control flow for authorization** — a reviewer suggested a `rescue ActiveRecord::RecordNotFound` branch for this; rejected in favor of explicit, readable conditionals. Exceptions for control flow are harder to read and often duplicate logic that already lives elsewhere.
4. **Model validations ≠ database constraints.** Validations give good UX (clean error messages); only DB-level constraints (unique indexes) are safe under concurrent requests. Current app has the former but not the latter for `Project#name` uniqueness — a known, accepted gap.
5. **Tailwind only compiles classes it can find by scanning files** — a class existing correctly in rendered HTML doesn't mean Tailwind generated CSS for it, if the watcher wasn't running when that class was introduced.
6. **Computed state vs. stored state** is a real, recurring system design decision (came up for both task-section-splitting and project-status) — worth explicitly naming which one you're choosing and why, every time.