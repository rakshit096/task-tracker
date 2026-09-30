# BASIC
User.all
User.first
User.last
User.find(1)
User.find_by(email: "x@example.com")

# FILTERING
User.where(active: true)
User.where(role: "admin")
User.where.not(role: "admin")

# COUNT / EXISTENCE
User.count
User.exists?

# SORTING / LIMIT
User.order(created_at: :desc)
User.limit(10)

# SELECTING DATA
User.select(:name, :email)
User.pluck(:name)
User.distinct

# AGGREGATIONS
Task.count
Task.sum(:hours)
Task.average(:hours)
Task.minimum(:hours)
Task.maximum(:hours)

# GROUPING
Task.group(:status).count

# SEARCH
Task.where("title LIKE ?", "%login%")

# UPDATE
task.update(status: "completed")
Task.where(status: "pending").update_all(priority: "low")

# DELETE
task.destroy
Task.where(status: "completed").destroy_all

# ASSOCIATIONS
user.tasks
task.user
user.tasks.create(title: "Learn Rails")

# JOINS
Task.joins(:user).where(users: { active: true })

# PRELOADING
Task.includes(:user)

# BATCH PROCESSING
User.find_each do |user|
  # ...
end

# CHAINING
Task.where(status: "pending")
    .order(created_at: :desc)
    .limit(5)


# Includes

Suppose you're displaying:

@tasks = Task.all

and in your view:

<% @tasks.each do |task| %>
  <%= task.title %>
  <%= task.user.name %>
<% end %>

You may end up with many database queries.

You can preload the users:

@tasks = Task.includes(:user)

Then:

<% @tasks.each do |task| %>
  <%= task.title %>
  <%= task.user.name %>
<% end %>

This is related to avoiding the N+1 query problem.