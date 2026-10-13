require "rails_helper"

RSpec.describe CustomerPolicy do
  let(:customer) { build_stubbed(:customer) }

  %i[admin project_manager sales].each do |role|
    context "as #{role}" do
      let(:user) { build_stubbed(:user, role) }
      subject { described_class.new(user, customer) }

      it { is_expected.to be_index }
      it { is_expected.to be_show }
      it { is_expected.to be_create }
      it { is_expected.to be_update }
      it { is_expected.to be_destroy }
    end
  end

  context "as viewer" do
    let(:user) { build_stubbed(:user, :viewer) }
    subject { described_class.new(user, customer) }

    it { is_expected.to be_index }
    it { is_expected.to be_show }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_destroy }
  end
end
