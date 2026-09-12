require "rails_helper"

RSpec.describe LineItem, type: :model do
  it_behaves_like "a billable line item", :line_item

  it "belongs to an order" do
    reflection = described_class.reflect_on_association(:order)
    expect(reflection.macro).to eq(:belongs_to)
    expect(reflection.options[:inverse_of]).to eq(:line_items)
  end
end
