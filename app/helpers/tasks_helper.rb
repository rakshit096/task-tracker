module TasksHelper
  def status_badge_class(status)
    case status
    when "pending" then "bg-gray-100 text-gray-700"
    when "in_progress" then "bg-blue-100 text-blue-700"
    when "done" then "bg-green-100 text-green-700"
    end
  end
end
