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

  describe "#nav_link" do
    it "marks the link active (and aria-current) when the section matches, even for a nested controller" do
      allow(helper).to receive(:controller_name).and_return("quotes")
      html = helper.nav_link("Leads", "/leads")
      expect(html).to have_selector("a.bg-primary\\/15.text-white[aria-current='page']", text: "Leads")
    end

    it "leaves the link inactive when the section does not match" do
      allow(helper).to receive(:controller_name).and_return("customers")
      html = helper.nav_link("Leads", "/leads")
      expect(html).to have_selector("a.text-neutral-content\\/70", text: "Leads")
      expect(html).not_to have_selector("a[aria-current]")
    end
  end
end
