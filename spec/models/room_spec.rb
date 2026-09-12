require "rails_helper"

RSpec.describe Room, type: :model do
  describe "validations" do
    it "requires a name" do
      room = build(:room, name: nil)
      expect(room).not_to be_valid
      expect(room.errors[:name]).to be_present
    end

    it "requires length to be present and greater than 0" do
      expect(build(:room, length: nil)).not_to be_valid
      expect(build(:room, length: 0)).not_to be_valid
    end

    it "requires width to be present and greater than 0" do
      expect(build(:room, width: nil)).not_to be_valid
      expect(build(:room, width: 0)).not_to be_valid
    end

    it "is valid with sane attributes" do
      expect(build(:room)).to be_valid
    end
  end

  describe "#calculate_area" do
    it "sets area to length * width before save" do
      room = create(:room, length: 10, width: 12)
      expect(room.area).to eq(120)
    end

    it "is nil until the room is saved" do
      room = build(:room, length: 10, width: 12)
      expect(room.area).to be_nil
    end
  end

  it "belongs to a quote" do
    reflection = described_class.reflect_on_association(:quote)
    expect(reflection.macro).to eq(:belongs_to)
    expect(reflection.options[:inverse_of]).to eq(:rooms)
  end
end
