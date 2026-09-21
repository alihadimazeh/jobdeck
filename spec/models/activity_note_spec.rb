require "rails_helper"

RSpec.describe ActivityNote, type: :model do
  describe "validations" do
    it "requires a body" do
      note = build(:activity_note, body: nil)
      expect(note).not_to be_valid
      expect(note.errors[:body]).to be_present
    end

    it "is valid with sane attributes" do
      expect(build(:activity_note)).to be_valid
    end
  end

  it "belongs to a polymorphic notable" do
    reflection = described_class.reflect_on_association(:notable)
    expect(reflection.macro).to eq(:belongs_to)
    expect(reflection.options[:polymorphic]).to be true
  end

  it "attaches to whichever notable it's given" do
    lead = create(:lead)
    note = create(:activity_note, notable: lead)
    expect(note.notable).to eq(lead)
    expect(note.notable_type).to eq("Lead")
  end
end
