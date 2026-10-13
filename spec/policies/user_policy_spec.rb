require "rails_helper"

RSpec.describe UserPolicy do
  let(:target_user) { build_stubbed(:user) }

  context "as admin" do
    let(:user) { build_stubbed(:user, :admin) }
    subject { described_class.new(user, target_user) }

    it { is_expected.to be_index }
    it { is_expected.to be_show }
    it { is_expected.to be_create }
    it { is_expected.to be_update }
    it { is_expected.to be_destroy }
  end

  %i[project_manager sales viewer].each do |role|
    context "as #{role}" do
      let(:user) { build_stubbed(:user, role) }
      subject { described_class.new(user, target_user) }

      it { is_expected.not_to be_index }
      it { is_expected.not_to be_show }
      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end
  end
end
