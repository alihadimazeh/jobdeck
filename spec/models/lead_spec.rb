require "rails_helper"

RSpec.describe Lead, type: :model do
  describe "enums" do
    it "backs status with the new | contacted | quoted | converted | lost values" do
      expect(described_class.statuses).to eq(
        "new" => 0, "contacted" => 1, "quoted" => 2, "converted" => 3, "lost" => 4
      )
    end

    it "backs job_type with the tile | flooring | materials | kitchen | mixed values" do
      expect(described_class.job_types).to eq(
        "tile" => 0, "flooring" => 1, "materials" => 2, "kitchen" => 3, "mixed" => 4
      )
    end

    # Regression test for the source-enum swap bug: spec is
    # walk_in | phone | referral | website | other, the original code had
    # referral/phone swapped. Integer-backed, so getting this wrong mislabels
    # existing rows rather than raising anything.
    it "backs source with the walk_in | phone | referral | website | other values" do
      expect(described_class.sources).to eq(
        "walk_in" => 0, "phone" => 1, "referral" => 2, "website" => 3, "other" => 4
      )
    end

    it "exposes suffixed predicates on every enum (suffix: true)" do
      lead = build(:lead, status: :quoted, job_type: :flooring, source: :referral)
      expect(lead.quoted_status?).to be true
      expect(lead.flooring_job_type?).to be true
      expect(lead.referral_source?).to be true
    end
  end

  describe "validations" do
    it "requires a title" do
      lead = build(:lead, title: nil)
      expect(lead).not_to be_valid
      expect(lead.errors[:title]).to be_present
    end
  end

  describe "#convert_to_job!" do
    it "creates a Job from the Lead, seeds an Order from the Quote's line items, and converts the Lead" do
      lead  = create(:lead, title: "Kitchen retile", job_type: :tile, estimated_value: 500)
      quote = create(:quote, :with_line_items, lead: lead, line_items_count: 2)

      expect { lead.convert_to_job!(quote) }
        .to change { lead.reload.status }.from("new").to("converted")

      job = lead.job
      expect(job).to be_present
      expect(job.title).to eq("Kitchen retile")
      expect(job.customer_id).to eq(lead.customer_id)

      order = job.orders.sole
      expect(order.customer_id).to eq(lead.customer_id)
      expect(order.lead_id).to eq(lead.id)
      expect(order.line_items.count).to eq(2)
    end

    it "raises and rolls back entirely if the Lead already has a Job" do
      lead  = create(:lead)
      quote = create(:quote, :with_line_items, lead: lead)
      lead.convert_to_job!(quote)
      original_job_id = lead.reload.job.id

      other_quote = create(:quote, lead: lead)

      expect { lead.convert_to_job!(other_quote) }
        .to raise_error(RuntimeError, /already been converted/)

      expect(Job.where(lead: lead).count).to eq(1)
      expect(lead.reload.job.id).to eq(original_job_id)
    end
  end

  describe "deletion semantics" do
    it "blocks destroy when the lead has an order, without mutating job or quotes first" do
      lead  = create(:lead)
      job   = create(:job, customer: lead.customer, lead: lead)
      quote = create(:quote, lead: lead, customer: lead.customer)
      order = create(:order, job: job, customer: lead.customer, lead: lead)

      expect(lead.destroy).to be false
      expect(lead.errors.full_messages).to include("Cannot delete record because dependent orders exist")

      expect(Lead.exists?(lead.id)).to be true
      expect(Quote.exists?(quote.id)).to be true
      expect(job.reload.lead_id).to eq(lead.id)
      expect(Order.exists?(order.id)).to be true
    end

    it "nullifies (not destroys) its job when destroyed with no orders in the way" do
      lead = create(:lead)
      job  = create(:job, customer: lead.customer, lead: lead)

      expect(lead.destroy).to be_truthy

      expect(Lead.exists?(lead.id)).to be false
      expect(Job.exists?(job.id)).to be true
      expect(job.reload.lead_id).to be_nil
    end

    it "destroys its quotes when destroyed with no orders in the way" do
      lead  = create(:lead)
      quote = create(:quote, lead: lead, customer: lead.customer)

      expect(lead.destroy).to be_truthy
      expect(Quote.exists?(quote.id)).to be false
    end

    it "destroys its activity notes when destroyed with no orders in the way" do
      lead = create(:lead)
      note = lead.activity_notes.create!(body: "test note")

      expect(lead.destroy).to be_truthy
      expect(ActivityNote.exists?(note.id)).to be false
    end

    it "destroys its documents when destroyed with no orders in the way" do
      lead = create(:lead)
      document = create(:document, documentable: lead)

      expect(lead.destroy).to be_truthy
      expect(Document.exists?(document.id)).to be false
    end
  end
end
