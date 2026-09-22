require "rails_helper"

# Browsers compile <input pattern> with the regex `v` flag; an invalid pattern there is
# silently ignored (every value passes). This checks the real browser actually enforces it.
RSpec.describe "Customer phone field pattern", type: :system, skip_authentication: true do
  let(:user) { create(:user) }

  before do
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign in"
    expect(page).to have_current_path(root_path)
  end

  def mismatch_for(value)
    fill_in "customer[phone]", with: value
    page.evaluate_script("document.getElementById('customer_phone').validity.patternMismatch")
  end

  it "accepts common phone formats and rejects obvious junk" do
    visit new_customer_path

    expect(mismatch_for("555-0100")).to be false
    expect(mismatch_for("(613) 555-0199")).to be false
    expect(mismatch_for("+1 613.555.0199")).to be false
    expect(mismatch_for("call me")).to be true
    expect(mismatch_for("555")).to be true
  end
end
