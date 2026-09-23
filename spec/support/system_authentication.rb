# Every controller requires authentication (app/controllers/concerns/authentication.rb).
# Unlike request specs, a system spec drives a real browser session, so signing in has to
# happen through an actual visit + form submit (not a raw POST) for the resulting signed
# cookie to end up in that browser session.
#
# The actual before(:each, type: :system) hook that calls sign_in_as lives in
# spec/rails_helper.rb, inside the same hook as `driven_by` - see the comment there for why
# it can't be a separate hook registered from this file.
#
# Specs exercising the unauthenticated path itself would opt out with
# `skip_authentication: true` at the describe/it level, same convention as
# spec/support/authentication.rb (request specs) - none currently need to.
module SystemAuthenticationHelpers
  def sign_in_as(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Sign in"

    # The sign-in form submits via Turbo (a fetch, not a real navigation), so
    # click_button returns as soon as the click fires - before the POST/redirect/page
    # swap actually finishes. Without waiting here, the very next `visit` in the spec
    # can race ahead of the browser actually receiving the session cookie. Capybara's
    # have_current_path matcher retries until it matches, so this blocks until sign-in
    # has genuinely completed.
    expect(page).to have_current_path(root_path)
  end
end

RSpec.configure do |config|
  config.include SystemAuthenticationHelpers, type: :system
end
