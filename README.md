# TaskTracker Application Architecture & Development Summary

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