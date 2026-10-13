require "rails_helper"

RSpec.describe QuotePolicy do
  let(:quote) { build_stubbed(:quote) }

  %i[admin project_manager sales].each do |role|
    context "as #{role}" do
      let(:user) { build_stubbed(:user, role) }
      subject { described_class.new(user, quote) }

      it { is_expected.to be_index }
      it { is_expected.to be_show }
      it { is_expected.to be_create }
      it { is_expected.to be_update }
      it { is_expected.to be_destroy }
      it { is_expected.to be_accept }
    end
  end

  context "as viewer" do
    let(:user) { build_stubbed(:user, :viewer) }
    subject { described_class.new(user, quote) }

    it { is_expected.to be_index }
    it { is_expected.to be_show }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_destroy }
    it { is_expected.not_to be_accept }
  end
end
