require "rails_helper"

RSpec.describe UsersMailer do
  describe "#invite" do
    let(:user) { create(:user, :sales) }
    let(:mail) { UsersMailer.invite(user) }

    it "renders the subject and recipient" do
      expect(mail.subject).to eq("You've been invited to Jobdeck")
      expect(mail.to).to eq([ user.email ])
    end

    it "includes a working account-setup link" do
      token = mail.body.encoded[%r{/account_setups/([^/"\s]+)/edit}, 1]

      expect(token).to be_present
      expect(User.find_by_token_for(:account_setup, token)).to eq(user)
    end
  end
end
