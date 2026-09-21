require "rails_helper"

RSpec.describe Job, type: :model do
  describe "enums" do
    it "backs status with the active | on_hold | completed | cancelled values" do
      expect(described_class.statuses).to eq(
        "active" => 0, "on_hold" => 1, "completed" => 2, "cancelled" => 3
      )
    end

    it "backs job_type with the tile | flooring | materials | kitchen | mixed values" do
      expect(described_class.job_types).to eq(
        "tile" => 0, "flooring" => 1, "materials" => 2, "kitchen" => 3, "mixed" => 4
      )
    end

    it "exposes suffixed predicates (suffix: true)" do
      job = build(:job, status: :on_hold)
      expect(job.on_hold_status?).to be true
    end
  end

  describe "validations" do
    it "requires a title" do
      job = build(:job, title: nil)
      expect(job).not_to be_valid
      expect(job.errors[:title]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a customer, with an optional lead" do
      expect(described_class.reflect_on_association(:customer).macro).to eq(:belongs_to)

      lead_reflection = described_class.reflect_on_association(:lead)
      expect(lead_reflection.macro).to eq(:belongs_to)
      expect(lead_reflection.options[:optional]).to be true
    end
  end

  describe "deletion semantics" do
    it "blocks destroy when the job has an order (restrict_with_error)" do
      job = create(:job)
      create(:order, job: job)

      expect(job.destroy).to be false
      expect(job.errors.full_messages).to include("Cannot delete record because dependent orders exist")
      expect(Job.exists?(job.id)).to be true
    end

    it "destroys cleanly when there are no orders" do
      job = create(:job)
      expect(job.destroy).to be_truthy
      expect(Job.exists?(job.id)).to be false
    end

    it "destroys its activity notes when destroyed with no orders in the way" do
      job  = create(:job)
      note = job.activity_notes.create!(body: "test note")

      expect(job.destroy).to be_truthy
      expect(ActivityNote.exists?(note.id)).to be false
    end

    it "destroys its documents when destroyed with no orders in the way" do
      job = create(:job)
      document = create(:document, documentable: job)

      expect(job.destroy).to be_truthy
      expect(Document.exists?(document.id)).to be false
    end
  end
end
