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

  describe ".by_urgency" do
    it "puts jobs past their end date first (most days over on top), then nearest end date, then no end date by start" do
      soon     = create(:job, end_date: 3.days.from_now.to_date, start_date: 20.days.ago.to_date)
      way_over = create(:job, end_date: 10.days.ago.to_date, start_date: 2.days.ago.to_date)
      no_end   = create(:job, end_date: nil, start_date: 40.days.ago.to_date)
      over     = create(:job, end_date: 2.days.ago.to_date, start_date: 1.day.ago.to_date)
      later    = create(:job, end_date: 30.days.from_now.to_date, start_date: 50.days.ago.to_date)
      # Scoped to these rows: Minitest fixture jobs can be committed in the shared test DB.
      mine = described_class.where(id: [ soon, way_over, no_end, over, later ])

      expect(mine.by_urgency).to eq([ way_over, over, soon, later, no_end ])
    end
  end

  describe "#days_over" do
    it "counts whole days an active job has run past its end date" do
      expect(build(:job, status: :active, end_date: 5.days.ago.to_date).days_over).to eq(5)
    end

    it "is nil on or before the end date, without one, or once the job isn't active" do
      expect(build(:job, status: :active, end_date: Date.current).days_over).to be_nil
      expect(build(:job, status: :active, end_date: nil).days_over).to be_nil
      expect(build(:job, status: :completed, end_date: 5.days.ago.to_date).days_over).to be_nil
    end
  end
end
