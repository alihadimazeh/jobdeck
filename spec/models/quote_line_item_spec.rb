require "rails_helper"

RSpec.describe QuoteLineItem, type: :model do
  it_behaves_like "a billable line item", :quote_line_item

  it "belongs to a quote" do
    reflection = described_class.reflect_on_association(:quote)
    expect(reflection.macro).to eq(:belongs_to)
    expect(reflection.options[:inverse_of]).to eq(:quote_line_items)
  end
end
