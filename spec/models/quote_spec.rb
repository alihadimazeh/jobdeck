require "rails_helper"

RSpec.describe Quote, type: :model do
  describe "enums" do
    it "backs status with the draft | sent | accepted | rejected | expired values" do
      expect(described_class.statuses).to eq(
        "draft" => 0, "sent" => 1, "accepted" => 2, "rejected" => 3, "expired" => 4
      )
    end

    it "exposes suffixed predicates (suffix: true)" do
      quote = build(:quote, status: :sent)
      expect(quote.sent_status?).to be true
    end
  end

  describe "#assign_quote_number" do
    it "auto-generates a QUO-<year>-<sequence> number on create" do
      quote = create(:quote)
      expect(quote.quote_number).to match(/\AQUO-#{Date.current.year}-\d{4}\z/)
    end

    it "increments the sequence for subsequent quotes in the same year" do
      first  = create(:quote)
      second = create(:quote)
      expect(second.quote_number.split("-").last.to_i).to eq(first.quote_number.split("-").last.to_i + 1)
    end
  end

  describe "#recalculate_totals" do
    it "sums quote_line_item totals into subtotal and applies tax_rate to total" do
      quote = create(:quote, tax_rate: 0.1)
      create(:quote_line_item, quote: quote, quantity: 2, unit_price: 10)
      create(:quote_line_item, quote: quote, quantity: 1, unit_price: 5)

      quote.reload.save!
      expect(quote.subtotal).to eq(25)
      expect(quote.total).to eq(27.5)
    end
  end

  describe "#total_area" do
    it "sums the area of all saved rooms" do
      quote = create(:quote)
      create(:room, quote: quote, length: 10, width: 10)
      create(:room, quote: quote, length: 5, width: 4)

      expect(quote.reload.total_area).to eq(120)
    end

    it "treats an unsaved/blank room's area as 0" do
      quote = create(:quote)
      quote.rooms.build(name: "Unsaved room")

      expect(quote.total_area).to eq(0)
    end
  end

  describe "#assign_customer_from_lead" do
    it "auto-sets customer_id from the lead when not given explicitly" do
      lead  = create(:lead)
      quote = Quote.create!(lead: lead, status: :draft, tax_rate: 0)
      expect(quote.customer_id).to eq(lead.customer_id)
    end

    it "does not override an explicitly-given customer_id" do
      lead        = create(:lead)
      other_lead  = create(:lead)
      quote       = Quote.create!(lead: lead, customer: other_lead.customer, status: :draft, tax_rate: 0)
      expect(quote.customer_id).to eq(other_lead.customer_id)
    end
  end

  describe "#only_one_accepted_quote_per_lead" do
    it "allows accepting a quote when no other quote on the lead is accepted" do
      lead  = create(:lead)
      quote = create(:quote, lead: lead, status: :sent)

      quote.status = :accepted
      expect(quote).to be_valid
    end

    it "rejects accepting a quote when another quote on the same lead is already accepted" do
      lead = create(:lead)
      create(:quote, :accepted, lead: lead)
      quote_b = create(:quote, lead: lead, status: :sent)

      quote_b.status = :accepted
      expect(quote_b).not_to be_valid
      expect(quote_b.errors[:status]).to include("already has an accepted quote for this lead")
    end

    it "does not run the guard for non-accepted status changes" do
      lead = create(:lead)
      create(:quote, :accepted, lead: lead)
      quote_b = create(:quote, lead: lead, status: :draft)

      quote_b.status = :rejected
      expect(quote_b).to be_valid
    end
  end

  describe "after_save conversion trigger" do
    it "converts the lead when status flips to accepted" do
      lead  = create(:lead)
      quote = create(:quote, :with_line_items, lead: lead, status: :sent)

      quote.update!(status: :accepted)

      expect(lead.reload).to be_converted_status
      expect(lead.job).to be_present
    end

    it "does not trigger conversion for other status changes" do
      lead  = create(:lead)
      quote = create(:quote, lead: lead, status: :draft)

      quote.update!(status: :sent)

      expect(lead.reload).to be_new_status
      expect(lead.job).to be_nil
    end

    it "does not re-trigger conversion on an unrelated update to an already-accepted quote" do
      lead  = create(:lead)
      quote = create(:quote, :with_line_items, lead: lead, status: :sent)
      quote.update!(status: :accepted)
      original_job_id = lead.reload.job.id

      expect { quote.update!(notes: "revised scope") }.not_to raise_error
      expect(lead.reload.job.id).to eq(original_job_id)
    end

    it "propagates the idempotency guard and rolls back the status change if the lead already converted" do
      lead = create(:lead)
      quote_a = create(:quote, :with_line_items, lead: lead, status: :sent)
      quote_a.update!(status: :accepted)

      quote_b = create(:quote, lead: lead, status: :sent)
      quote_a.update!(status: :rejected)

      expect { quote_b.update!(status: :accepted) }.to raise_error(RuntimeError, /already been converted/)
      expect(Job.where(lead: lead).count).to eq(1)
    end
  end
end
