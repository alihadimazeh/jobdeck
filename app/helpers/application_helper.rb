module ApplicationHelper
  # No Pagy frontend include needed: this Pagy version (43.x) puts nav-rendering
  # methods (e.g. #series_nav) directly on the Pagy object #pagy returns in the
  # controller, called in views as `@pagy.series_nav` - not a separate helper
  # module. See app/controllers/application_controller.rb (`include Pagy::Method`).

  # Status -> daisyUI badge variant, shared across every resource's status enum.
  # "archived" is :error (not :neutral like "inactive") to preserve the visual
  # distinction the old inline badge hash made (customers/_customer.html.erb,
  # pre-Step-8: active=green, inactive=gray, archived=red) - archiving is a more
  # final state than just being inactive.
  STATUS_VARIANTS = {
    "new" => :neutral, "contacted" => :info, "quoted" => :warning, "converted" => :success, "lost" => :error,
    "draft" => :neutral, "sent" => :info, "accepted" => :success, "rejected" => :error, "expired" => :warning,
    "active" => :success, "on_hold" => :warning, "completed" => :info, "cancelled" => :error,
    "confirmed" => :info, "invoiced" => :warning, "paid" => :success,
    "inactive" => :neutral, "archived" => :error
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

  # The repeated "address line 1 / address line 2 / city, province, postal"
  # block used on Customer and Job show pages. Returns nil (not "—") when
  # there's no address at all, so callers relying on shared/_detail_list's own
  # blank-value fallback ("value.presence || —") get that "—" instead of a
  # dangling empty line.
  def format_address(address_line_1:, address_line_2: nil, city: nil, province: nil, postal_code: nil)
    return nil if address_line_1.blank?

    lines = [ address_line_1, address_line_2 ].compact_blank
    region_line = [ city, province, postal_code ].compact_blank.join(", ")
    lines << region_line if region_line.present?
    safe_join(lines, tag.br)
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

  # True when the model has an unconditional presence validation on attr (or, for a
  # foreign key like customer_id, on its required belongs_to) - so required markers
  # stay in sync with the real validations instead of being annotated per form.
  def field_required?(record, attr)
    return false unless record.class.respond_to?(:validators_on)

    # belongs_to's own presence validator carries an internal `if:` in Rails 8.1, so
    # read the association's optional flag instead of filtering its validator.
    association = record.class.reflect_on_association(attr.to_s.delete_suffix("_id")) if attr.to_s.end_with?("_id")
    return !association.options[:optional] && record.class.belongs_to_required_by_default if association&.macro == :belongs_to

    record.class.validators_on(attr).any? do |validator|
      validator.kind == :presence && (validator.options.keys & %i[if unless on allow_nil allow_blank]).empty?
    end
  end

  def nav_link(label, path, section: label)
    active = nav_section_active?(section)
    base  = "flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors"
    style = active ? "bg-primary/15 text-primary-content" : "text-neutral-content/70 hover:text-primary-content hover:bg-neutral-content/5"
    link_to(label, path, class: "#{base} #{style}", "aria-current": (active ? "page" : nil))
  end
end
