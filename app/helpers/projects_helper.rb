module ProjectsHelper
  def project_status_badge_class(status)
    case status
    when "planning" then "bg-gray-100 text-gray-700"
    when "in_progress" then "bg-blue-100 text-blue-700"
    when "completed" then "bg-green-100 text-green-700"
    when "on_hold" then "bg-yellow-200 text-yellow-800"
    end
  end
end
