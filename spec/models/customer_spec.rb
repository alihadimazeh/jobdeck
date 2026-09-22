require "rails_helper"

RSpec.describe Customer, type: :model do
  describe "enums" do
    it "backs status with the active | inactive | archived values" do
      expect(described_class.statuses).to eq(
        "active" => "active", "inactive" => "inactive", "archived" => "archived"
      )
    end

    it "exposes suffixed predicates (suffix: true)" do
      customer = build(:customer, status: :inactive)
      expect(customer.inactive_status?).to be true
    end
  end

  describe "#archive!" do
    it "sets status to archived" do
      customer = create(:customer, status: :active)
      customer.archive!
      expect(customer.reload).to be_archived_status
    end
  end

  describe ".visible" do
    it "excludes archived customers but includes active and inactive ones" do
      active_customer   = create(:customer, status: :active)
      inactive_customer = create(:customer, status: :inactive)
      archived_customer = create(:customer, status: :archived)

      expect(Customer.visible).to include(active_customer, inactive_customer)
      expect(Customer.visible).not_to include(archived_customer)
    end
  end

  describe "validations" do
    it "requires first_name, last_name, and phone" do
      customer = build(:customer, first_name: "", last_name: "", phone: "")
      expect(customer).not_to be_valid
      expect(customer.errors[:first_name]).to be_present
      expect(customer.errors[:last_name]).to be_present
      expect(customer.errors[:phone]).to be_present
    end

    it "is valid with sane attributes" do
      expect(build(:customer)).to be_valid
    end
  end

  describe "#full_name" do
    it "joins first and last name" do
      customer = build(:customer, first_name: "Ada", last_name: "Lovelace")
      expect(customer.full_name).to eq("Ada Lovelace")
    end
  end

  describe "deletion semantics" do
    it "destroys the customer's documents (and their files) with it" do
      customer = create(:customer)
      create(:document, documentable: customer)

      expect { customer.destroy }.to change(Document, :count).by(-1)
      expect(customer).to be_destroyed
    end

    it "keeps documents when a delete is blocked by history (the archive path)" do
      customer = create(:customer)
      create(:job, customer: customer)
      create(:document, documentable: customer)

      expect { customer.destroy }.not_to change(Document, :count)
      expect(customer.reload).not_to be_destroyed
    end

    it "blocks destroy when the customer has a job directly (restrict_with_error)" do
      customer = create(:customer)
      create(:job, customer: customer)

      expect(customer.destroy).to be false
      expect(customer.errors.full_messages).to include("Cannot delete record because dependent jobs exist")
      expect(Customer.exists?(customer.id)).to be true
    end

    # Regression test for the nested-cascade bug: Customer's `leads, dependent: :destroy`
    # used to run *before* its own `jobs`/`orders` restrict_with_error checks, so deleting
    # a Customer with a converted Lead would tear into the Lead's own destroy chain first --
    # nullifying the Job's lead_id and destroying its Quotes -- before ever reaching a
    # restrict check, and the abort deep in that chain never surfaced an error on the
    # Customer at all. See TODO.md -> Bugs and CLAUDE.md -> "Deletion Semantics".
    it "blocks destroy when a converted lead's order exists, without mutating anything" do
      customer = create(:customer)
      lead     = create(:lead, customer: customer)
      job      = create(:job, customer: customer, lead: lead)
      quote    = create(:quote, lead: lead, customer: customer)
      order    = create(:order, job: job, customer: customer, lead: lead)

      expect(customer.destroy).to be false
      expect(customer.errors.full_messages).to include("Cannot delete record because dependent jobs exist")

      expect(Customer.exists?(customer.id)).to be true
      expect(Lead.exists?(lead.id)).to be true
      expect(Quote.exists?(quote.id)).to be true
      expect(Order.exists?(order.id)).to be true
      expect(job.reload.lead_id).to eq(lead.id)
    end

    it "cascades leads and quotes when there are no jobs or orders" do
      customer = create(:customer)
      lead     = create(:lead, customer: customer)
      quote    = create(:quote, lead: lead, customer: customer)

      expect(customer.destroy).to be_truthy

      expect(Customer.exists?(customer.id)).to be false
      expect(Lead.exists?(lead.id)).to be false
      expect(Quote.exists?(quote.id)).to be false
    end
  end
end
