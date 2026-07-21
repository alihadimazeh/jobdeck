module JobsHelper
  JOB_STATUS_BADGE_CLASSES = {
    "active"    => "bg-green-100 text-green-700",
    "on_hold"   => "bg-amber-100 text-amber-700",
    "completed" => "bg-blue-100 text-blue-700",
    "cancelled" => "bg-red-100 text-red-600"
  }.freeze

  LEAD_STATUS_BADGE_CLASSES = {
    "new"       => "bg-gray-100 text-gray-600",
    "contacted" => "bg-blue-100 text-blue-700",
    "quoted"    => "bg-amber-100 text-amber-700",
    "converted" => "bg-green-100 text-green-700",
    "lost"      => "bg-red-100 text-red-600"
  }.freeze

  def job_status_badge_classes(status)
    JOB_STATUS_BADGE_CLASSES[status] || "bg-gray-100 text-gray-600"
  end

  def lead_status_badge_classes(status)
    LEAD_STATUS_BADGE_CLASSES[status] || "bg-gray-100 text-gray-600"
  end
end
