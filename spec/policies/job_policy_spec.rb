require "rails_helper"

RSpec.describe JobPolicy do
  let(:job) { build_stubbed(:job) }

  %i[admin project_manager].each do |role|
    context "as #{role}" do
      let(:user) { build_stubbed(:user, role) }
      subject { described_class.new(user, job) }

      it { is_expected.to be_index }
      it { is_expected.to be_show }
      it { is_expected.to be_create }
      it { is_expected.to be_update }
      it { is_expected.to be_destroy }
    end
  end

  %i[sales viewer].each do |role|
    context "as #{role}" do
      let(:user) { build_stubbed(:user, role) }
      subject { described_class.new(user, job) }

      it { is_expected.to be_index }
      it { is_expected.to be_show }
      it { is_expected.not_to be_create }
      it { is_expected.not_to be_update }
      it { is_expected.not_to be_destroy }
    end
  end
end
