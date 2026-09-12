require "rails_helper"

RSpec.describe Order, type: :model do
  describe "enums" do
    it "backs status with the draft | confirmed | invoiced | paid | cancelled values" do
      expect(described_class.statuses).to eq(
        "draft" => 0, "confirmed" => 1, "invoiced" => 2, "paid" => 3, "cancelled" => 4
      )
    end

    it "exposes suffixed predicates (suffix: true)" do
      order = build(:order, status: :invoiced)
      expect(order.invoiced_status?).to be true
    end
  end

  describe "associations" do
    it "belongs to job and customer, with an optional lead" do
      expect(described_class.reflect_on_association(:job).macro).to eq(:belongs_to)
      expect(described_class.reflect_on_association(:customer).macro).to eq(:belongs_to)

      lead_reflection = described_class.reflect_on_association(:lead)
      expect(lead_reflection.macro).to eq(:belongs_to)
      expect(lead_reflection.options[:optional]).to be true
    end

    it "destroys its line items when destroyed" do
      order     = create(:order)
      line_item = create(:line_item, order: order)

      order.destroy
      expect(LineItem.exists?(line_item.id)).to be false
    end
  end

  describe "#assign_order_number" do
    it "auto-generates an ORD-<year>-<sequence> number on create" do
      order = create(:order)
      expect(order.order_number).to match(/\AORD-#{Date.current.year}-\d{4}\z/)
    end

    it "increments the sequence for subsequent orders in the same year" do
      first  = create(:order)
      second = create(:order)
      expect(second.order_number.split("-").last.to_i).to eq(first.order_number.split("-").last.to_i + 1)
    end
  end

  describe "#assign_customer_from_job" do
    it "auto-sets customer_id from the job when not given explicitly" do
      job   = create(:job)
      order = Order.create!(job: job, status: :draft, tax_rate: 0)
      expect(order.customer_id).to eq(job.customer_id)
    end

    it "does not override an explicitly-given customer_id" do
      job         = create(:job)
      other_job   = create(:job)
      order       = Order.create!(job: job, customer: other_job.customer, status: :draft, tax_rate: 0)
      expect(order.customer_id).to eq(other_job.customer_id)
    end
  end

  describe "#recalculate_totals" do
    it "sums line item totals into subtotal and applies tax_rate to total" do
      order = create(:order, tax_rate: 0.1)
      create(:line_item, order: order, quantity: 2, unit_price: 10)
      create(:line_item, order: order, quantity: 1, unit_price: 5)

      order.reload.save!
      expect(order.subtotal).to eq(25)
      expect(order.total).to eq(27.5)
    end
  end
end
