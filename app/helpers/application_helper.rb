module ApplicationHelper
  # Status -> daisyUI badge variant, shared across every resource's status enum.
  # Consumed by status_badge below, which in turn renders app/views/shared/_badge
  # (arrives in Step 5) - so status_badge is inert/unused until then, and the
  # per-resource *_status_badge_classes helpers keep doing the real work until
  # each resource's views migrate to status_badge directly (Steps 8-12).
  STATUS_VARIANTS = {
    "new" => :neutral, "contacted" => :info, "quoted" => :warning, "converted" => :success, "lost" => :error,
    "draft" => :neutral, "sent" => :info, "accepted" => :success, "rejected" => :error, "expired" => :warning,
    "active" => :success, "on_hold" => :warning, "completed" => :info, "cancelled" => :error,
    "confirmed" => :info, "invoiced" => :warning, "paid" => :success,
    "inactive" => :neutral, "archived" => :neutral
  }.freeze

  def status_badge(record, status = nil)
    value = (status || record.status).to_s
    render "shared/badge", label: value.humanize, variant: STATUS_VARIANTS.fetch(value, :neutral)
  end

  def format_date(date, fallback = "—")
    date ? date.strftime("%b %d, %Y") : fallback
  end

  def format_currency(amount, fallback = "—")
    amount ? number_to_currency(amount) : fallback
  end

  # link_to/button_to wrapper that applies daisyUI's btn classes consistently.
  def btn(label, path, variant: :primary, method: :get, confirm: nil, **options)
    classes = "btn btn-#{variant} #{options.delete(:class)}".strip
    return link_to(label, path, class: classes, **options) if method == :get

    button_to label, path, method: method, class: classes,
      form: { data: (confirm ? { turbo_confirm: confirm } : {}) }, **options
  end

  # Which controllers belong to each sidebar section, so a nested resource
  # (e.g. a Quote, which lives under Leads) still highlights its parent nav item.
  SECTION_CONTROLLERS = {
    "Dashboard" => %w[dashboard],
    "Customers" => %w[customers],
    "Leads"     => %w[leads quotes rooms quote_line_items],
    "Jobs"      => %w[jobs orders line_items]
  }.freeze

  def nav_section_active?(section)
    SECTION_CONTROLLERS.fetch(section, []).include?(controller_name)
  end

  def nav_link(label, path, section: label)
    active = nav_section_active?(section)
    base  = "flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors"
    style = active ? "bg-white/10 text-white" : "text-gray-400 hover:text-white hover:bg-white/5"
    link_to(label, path, class: "#{base} #{style}", "aria-current": (active ? "page" : nil))
  end
end
