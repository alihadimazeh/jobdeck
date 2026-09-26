require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_date" do
    it "returns the em-dash fallback for nil" do
      expect(helper.format_date(nil)).to eq("—")
    end

    it "formats a date as 'Mon DD, YYYY'" do
      expect(helper.format_date(Date.new(2026, 3, 5))).to eq("Mar 05, 2026")
    end

    it "accepts a custom fallback" do
      expect(helper.format_date(nil, "n/a")).to eq("n/a")
    end
  end

  describe "#format_currency" do
    it "returns the em-dash fallback for nil" do
      expect(helper.format_currency(nil)).to eq("—")
    end

    it "formats a number as currency" do
      expect(helper.format_currency(1234.5)).to eq("$1,234.50")
    end
  end

  describe "#format_address" do
    it "returns nil when there is no address line 1 (so shared/_detail_list falls back to —)" do
      expect(helper.format_address(address_line_1: nil)).to be_nil
      expect(helper.format_address(address_line_1: "")).to be_nil
    end

    it "joins the given lines with <br>, omitting blank ones" do
      html = helper.format_address(
        address_line_1: "1 Main St", address_line_2: "Unit 4",
        city: "Ottawa", province: "ON", postal_code: "K1A 0A1"
      )
      expect(html).to eq("1 Main St<br>Unit 4<br>Ottawa, ON, K1A 0A1")
      expect(html).to be_html_safe
    end

    it "omits address_line_2 and the region line when they're blank" do
      html = helper.format_address(address_line_1: "1 Main St")
      expect(html).to eq("1 Main St")
    end
  end

  describe "#status_badge" do
    it "renders the humanized status with its mapped variant" do
      customer = build(:customer, status: "active")
      html = helper.status_badge(customer)
      expect(html).to have_selector("span.badge.badge-success", text: "Active")
    end

    it "gives archived a distinct (error) variant from inactive (neutral)" do
      customer = build(:customer, status: "archived")
      expect(helper.status_badge(customer)).to have_selector("span.badge.badge-error", text: "Archived")

      customer.status = "inactive"
      expect(helper.status_badge(customer)).to have_selector("span.badge.badge-neutral", text: "Inactive")
    end

    it "accepts an explicit status, overriding the record's own" do
      customer = build(:customer, status: "active")
      expect(helper.status_badge(customer, "archived")).to have_selector(".badge-error", text: "Archived")
    end
  end

  describe "#btn" do
    it "renders a link for the default GET method" do
      html = helper.btn("Edit", "/customers/1")
      expect(html).to have_selector("a.btn.btn-primary[href='/customers/1']", text: "Edit")
    end

    it "applies the requested variant" do
      html = helper.btn("Cancel", "/customers/1", variant: :ghost)
      expect(html).to have_selector("a.btn.btn-ghost")
    end

    it "renders a button_to form for non-GET methods, with turbo_confirm when given" do
      html = helper.btn("Delete", "/customers/1", variant: :error, method: :delete, confirm: "Sure?")
      expect(html).to have_selector("form[action='/customers/1'] input[name='_method'][value='delete']", visible: false)
      expect(html).to have_selector("form[data-turbo-confirm='Sure?']", visible: false)
      expect(html).to have_selector("button.btn.btn-error", text: "Delete")
    end
  end

  describe "#nav_section_active?" do
    it "is true when the current controller is in that section" do
      allow(helper).to receive(:controller_name).and_return("quotes")
      expect(helper.nav_section_active?("Leads")).to be true
    end

    it "is false otherwise" do
      allow(helper).to receive(:controller_name).and_return("orders")
      expect(helper.nav_section_active?("Leads")).to be false
    end

    it "returns false for an unknown section instead of raising" do
      allow(helper).to receive(:controller_name).and_return("customers")
      expect(helper.nav_section_active?("Nonexistent")).to be false
    end
  end

  describe "#field_required?" do
    it "is true for an unconditional presence validation" do
      expect(helper.field_required?(Customer.new, :first_name)).to be true
      expect(helper.field_required?(Room.new, :length)).to be true
    end

    it "is false for an attribute with no presence validation" do
      expect(helper.field_required?(Customer.new, :email)).to be false
      expect(helper.field_required?(ActivityNote.new, :author)).to be false
    end

    it "follows belongs_to for foreign keys: required unless optional" do
      expect(helper.field_required?(Lead.new, :customer_id)).to be true
      expect(helper.field_required?(Job.new, :lead_id)).to be false
    end
  end

  describe "#nav_link" do
    it "marks the link active (and aria-current) when the section matches, even for a nested controller" do
      allow(helper).to receive(:controller_name).and_return("quotes")
      html = helper.nav_link("Leads", "/leads")
      expect(html).to have_selector("a.bg-primary\\/15.text-primary-content[aria-current='page']", text: "Leads")
    end

    it "leaves the link inactive when the section does not match" do
      allow(helper).to receive(:controller_name).and_return("customers")
      html = helper.nav_link("Leads", "/leads")
      expect(html).to have_selector("a.text-neutral-content\\/70", text: "Leads")
      expect(html).not_to have_selector("a[aria-current]")
    end
  end
end
