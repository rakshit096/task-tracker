# Task Tracker

A Rails 8 learning project — a lightweight task/issue tracker (like a mini Jira/Linear) built to cover core backend concepts (authentication, authorization, associations, background jobs, Turbo Streams, and a token-authenticated JSON API) with a light, server-rendered frontend.

## Tech stack

- **Ruby** 3.2.0
- **Rails** 8.1.3.1
- **Database:** SQLite (via multiple logical databases: primary, cache, queue, cable)
- **Frontend:** Server-rendered ERB views + Tailwind CSS + Turbo (Hotwire) — no separate JS framework
- **Background jobs:** Solid Queue (database-backed, no Redis required)
- **Auth:** Rails 8's built-in cookie-session authentication generator + custom opaque Bearer token auth for API access

## Features

### Authentication
- Sign up (`/registration/new`), sign in / sign out (`/session/new`)
- Forgot password flow with a signed, expiring (15-minute) reset token, emailed via `PasswordsMailer` (logged to console in development)
- All pages require login by default except sign-up, sign-in, and password reset

### Projects
- Each user has a private list of projects, visible and editable only by their owner
- Full CRUD (create, view, edit, delete)

### Tasks
- Nested under projects (`/projects/:project_id/tasks`)
- Fields: title, description, status (`pending` / `in_progress` / `done`, via a Rails enum), assignee (any registered user)
- Inline status updates via **Turbo Streams** — changing the status dropdown updates the task in place with no full page reload and no custom JavaScript
- Full CRUD

### Notifications
- When a task's assignee changes, a background job (`TaskAssignmentNotifierJob`) sends an email via `TaskMailer`, decoupled from the web request using **Solid Queue**
- In development, "sent" emails are logged to `log/development.log` rather than actually delivered

### JSON API
- Each user has a personal `api_token` (via `has_secure_token`)
- External clients can authenticate with `Authorization: Bearer <token>` instead of a session cookie
- `GET /projects/:project_id/tasks.json` returns that project's tasks as JSON, scoped to the authenticated user's own projects

### Authorization pattern
Every database lookup is scoped through the current user (e.g. `Current.user.projects.find(params[:id])`), rather than a bare `Project.find(...)`. This means a user can never access another user's projects or tasks, even by guessing IDs in the URL — an unauthorized record is simply unreachable rather than blocked by a manual check.

## Architecture notes

- **`Current`** (`ActiveSupport::CurrentAttributes`) holds `session` and `user` for the duration of a request, avoiding the need to pass `current_user` through every method call.
- **`Authentication`** concern (`app/controllers/concerns/authentication.rb`) enforces login via `before_action :require_authentication` on all controllers by default, with `allow_unauthenticated_access` to opt specific actions out (e.g. sign-up, sign-in). It tries cookie-session auth first, then falls back to Bearer token auth.
- **Solid Queue** requires its own database connection, separate from the primary one — configured per environment in `config/database.yml` (`primary` / `cache` / `queue` / `cable`) and enabled via `config.active_job.queue_adapter = :solid_queue` and `config.solid_queue.connects_to` in `config/environments/development.rb`.
- **Token auth is opaque, not JWT** — `api_token` is a random string looked up in the database on every request, not a self-contained signed payload.

## Running locally

### Prerequisites
- Ruby 3.2.0
- Rails 8.1.3.1
- Bundler

### Setup

```bash
bundle install
bin/rails db:prepare   # creates and migrates all databases (primary, cache, queue, cable)
```

### Start the app

You need **three processes running simultaneously**, each in its own terminal:

```bash
# Terminal 1 — web server
bin/rails server
```

```bash
# Terminal 2 — background job worker (Solid Queue)
bin/jobs
```

```bash
# Terminal 3 — Tailwind CSS watcher (rebuilds styles on view changes)
bin/rails tailwindcss:watch
```

Then visit **http://localhost:3000**.

> If `foreman` is installed (`gem install foreman`), you can instead run `bin/dev` to start the web server and Tailwind watcher together in one command — you'll still need `bin/jobs` running separately.

### Using the JSON API

1. Generate an API token for a user in the Rails console:
   ```bash
   bin/rails console
   ```
   ```ruby
   user = User.find_by(email_address: "you@example.com")
   user.regenerate_api_token
   user.api_token
   ```
2. Call the API with the token:
   ```bash
   curl http://localhost:3000/projects.json \
     -H "Authorization: Bearer YOUR_TOKEN_HERE"
   ```

## Known limitations / possible next steps

- Session cookies and API tokens currently **never expire** — fine for a learning project, but a production app would typically add session timeouts and token rotation/expiry.
- Task assignees can be **any** registered user, not just members of that specific project — there's no "project membership" concept yet.
- No model/controller validations beyond basic presence checks — a planned next step.
- No automated test suite yet (Minitest) — a planned next step.



# Application Architecture & Development Summary

## 1. App Setup
* **Command**: `rails new task_tracker --css=tailwind`
* **Stack**: Rails 8 with Tailwind CSS, Propshaft asset pipeline, Import maps, SQLite database, and default Solid Queue / Solid Cache / Solid Cable integration.

## 2. Authentication (Cookie-Based)
* **Generator**: Executed `bin/rails generate authentication` to scaffold `User` and `Session` models, `SessionsController`, `PasswordsController`, and the `Authentication` concern.
* **Security Enforcement**: The `Authentication` concern enforces login globally across all controllers via `before_action :require_authentication`, unless explicitly whitelisted using `allow_unauthenticated_access`.
* **Global Request State**: Utilizes `ActiveSupport::CurrentAttributes` (`Current.session` / `Current.user`) to provide thread-isolated, request-wide access to authenticated state.
* **Routing**: Added `root "sessions#new"` prior to setting up main application resources.

## 3. Registration (Sign-Up Flow)
* **Controller**: Custom-built `RegistrationsController` (`new` and `create` actions) whitelisted with `allow_unauthenticated_access`.
* **Session Initialization**: Invokes `start_new_session_for @user` upon successful creation to log the user in immediately.
* **User Interface**: Linked "Sign up" action directly from the login template.

## 4. Password Reset Mechanism
* **Built-in Generator Integration**: Utilizes `PasswordsController` and `PasswordsMailer` backed by `generates_token_for`.
* **Token Security**: Tokens are signed and expiring (15-minute TTL), tied dynamically to the password salt so that previous reset links invalidate automatically upon password updates.
* **Development Emailing**: Configured to log output directly to `development.log`.

## 5. Core Data Models (Project & Task)
* **Associations**:
  * `User`: `has_many :projects`
  * `Project`: `belongs_to :user`, `has_many :tasks`
  * `Task`: `belongs_to :project`, `belongs_to :assignee, class_name: "User", optional: true`
* **Attributes & Validations**:
  * `status`: Defined via Active Record `enum` (`pending`, `in_progress`, `done`).
  * `validates`: Presence checks configured on `Project#name` and `Task#title`.

## 6. Controllers & Views Architecture
* **Routing Structure**: Standard RESTful resource routing for `ProjectsController`, with a nested `TasksController` under `/projects/:project_id/tasks`.
* **Strict Authorization Pattern**: Multi-tenant data scoping enforced by traversing through the logged-in user context (`Current.user.projects.find(...)` and `@project.tasks.find(...)`), preventing unauthorized access via direct parameter tampering.
* **Root Route**: Updated to `root "projects#index"` once project resources were established.

## 7. Reactive UI with Turbo Streams
* **Status Updates**: Configured `update_status` member route and action on tasks.
* **Unobtrusive JavaScript**: Implemented auto-submitting `<select>` dropdowns using `onchange: "this.form.requestSubmit()"` handled natively by Turbo.
* **Targeted DOM Replacement**: `update_status.turbo_stream.erb` evaluates `turbo_stream.replace dom_id(@task)` to swap out the specific task `<li>` element without a full page refresh.

## 8. Asynchronous Background Jobs
* **Components**: `TaskAssignmentNotifierJob` coupled with `TaskMailer#assigned`.
* **Model Lifecycle Hooks**: Added `after_commit :notify_assignee, if: :saved_change_to_assignee_id?` on `Task` to enqueue jobs asynchronously via `perform_later`.
* **Solid Queue Setup**: Multi-database setup configured in `database.yml` (splitting `primary`, `cache`, `queue`, and `cable` environments), set `config.active_job.queue_adapter = :solid_queue`, and defined `config.solid_queue.connects_to` inside `config/environments/development.rb`.
* **Execution**: Worker process runs independently via `bin/jobs`.

## 9. JSON API & Dual Authentication Strategy
* **Token Generation**: Added `has_secure_token :api_token` to `User`.
* **Current Model Enhancement**: Refactored `Current` to hold `user` directly to support both cookie sessions and token-based requests.
* **Layered Authentication**: Updated `Authentication` concern to attempt authentication via cookie session first, falling back to `Authorization: Bearer <token>` (`resume_session_by_token`) before redirecting.
* **JSON Serialization**: `TasksController#index` supports explicit JSON output scoped via `@tasks.as_json(only: [:id, :title, :description, :status, :assignee_id])`.