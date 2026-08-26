module OrdersHelper
  ORDER_STATUS_BADGE_CLASSES = {
    "draft"     => "bg-gray-100 text-gray-600",
    "confirmed" => "bg-blue-100 text-blue-700",
    "invoiced"  => "bg-amber-100 text-amber-700",
    "paid"      => "bg-green-100 text-green-700",
    "cancelled" => "bg-red-100 text-red-600"
  }.freeze

  def order_status_badge_classes(status)
    ORDER_STATUS_BADGE_CLASSES[status] || "bg-gray-100 text-gray-600"
  end
end
