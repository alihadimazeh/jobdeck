module QuotesHelper
  QUOTE_STATUS_BADGE_CLASSES = {
    "draft"    => "bg-gray-100 text-gray-600",
    "sent"     => "bg-blue-100 text-blue-700",
    "accepted" => "bg-green-100 text-green-700",
    "rejected" => "bg-red-100 text-red-600",
    "expired"  => "bg-amber-100 text-amber-700"
  }.freeze

  def quote_status_badge_classes(status)
    QUOTE_STATUS_BADGE_CLASSES[status] || "bg-gray-100 text-gray-600"
  end
end
