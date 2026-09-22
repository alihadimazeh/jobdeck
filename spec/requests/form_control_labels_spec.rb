require "rails_helper"

# Every visible form control needs an accessible name: a <label for>, a wrapping <label>,
# or an aria-label. Placeholder text doesn't count - it disappears once the user types.
RSpec.describe "Form control labels", type: :request do
  def unlabeled_controls(html)
    doc = Nokogiri::HTML(html)
    controls = doc.css("input, select, textarea").reject do |el|
      %w[hidden submit button].include?(el["type"])
    end

    controls.reject do |el|
      el["aria-label"].present? ||
        el["aria-labelledby"].present? ||
        el.ancestors("label").any? ||
        (el["id"].present? && doc.at_css("label[for='#{el['id']}']"))
    end.map { |el| el["name"] || el.to_html[0, 80] }
  end

  let(:customer) { create(:customer) }
  let(:lead)     { create(:lead, customer: customer) }
  let(:job)      { create(:job, customer: customer) }

  it "labels the search and status filter on the Lead index" do
    get leads_path
    expect(unlabeled_controls(response.body)).to eq([])
    expect(response.body).to include("Filter by status")
  end

  it "labels every control on the Quote form, including the JS row templates" do
    get new_lead_quote_path(lead)
    expect(unlabeled_controls(response.body)).to eq([])
  end

  it "labels every control on the Order form, including the JS row templates" do
    get new_job_order_path(job)
    expect(unlabeled_controls(response.body)).to eq([])
  end

  it "labels the item_type select on an existing order's line item rows" do
    order = create(:order, job: job, customer: customer)
    create(:line_item, order: order)
    get edit_order_path(order)

    expect(response.body).to match(/<select aria-label="Type"[^>]*line_items_attributes\]\[0\]\[item_type\]/)
    expect(unlabeled_controls(response.body)).to eq([])
  end
end
