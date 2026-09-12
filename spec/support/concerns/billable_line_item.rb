# Shared behavior contributed by the BillableLineItem concern
# (app/models/concerns/billable_line_item.rb), exercised identically against
# both LineItem and QuoteLineItem so the two models can't silently drift
# apart from each other.
RSpec.shared_examples "a billable line item" do |factory_name|
  describe "validations" do
    it "requires item_type" do
      record = build(factory_name, item_type: nil)
      expect(record).not_to be_valid
      expect(record.errors[:item_type]).to be_present
    end

    it "requires description" do
      record = build(factory_name, description: nil)
      expect(record).not_to be_valid
      expect(record.errors[:description]).to be_present
    end

    it "requires quantity to be greater than 0" do
      record = build(factory_name, quantity: 0)
      expect(record).not_to be_valid
      expect(record.errors[:quantity]).to be_present
    end

    it "requires unit_price to be greater than or equal to 0" do
      record = build(factory_name, unit_price: -1)
      expect(record).not_to be_valid
      expect(record.errors[:unit_price]).to be_present
    end

    it "is valid with sane attributes" do
      expect(build(factory_name)).to be_valid
    end
  end

  describe "#calculate_total" do
    it "sets total to quantity * unit_price before save" do
      record = create(factory_name, quantity: 3, unit_price: 10)
      expect(record.total).to eq(30)
    end

    it "recalculates total when quantity or unit_price changes" do
      record = create(factory_name, quantity: 2, unit_price: 5)
      record.update!(quantity: 4)
      expect(record.total).to eq(20)
    end
  end

  describe "item_type enum" do
    it "exposes suffixed predicate methods (suffix: true)" do
      record = build(factory_name, item_type: :labor)
      expect(record.labor_item_type?).to be true
      expect(record.material_item_type?).to be false
    end

    it "backs item_type with the material | labor | other values" do
      expect(described_class.item_types).to eq(
        "material" => 0, "labor" => 1, "other" => 2
      )
    end
  end
end
