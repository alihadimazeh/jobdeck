# Every controller now requires authentication (app/controllers/concerns/authentication.rb),
# so request specs need a signed-in session by default. A real POST to /session (not a
# Current.session= shortcut) so the signed cookie the Authentication concern reads is
# actually set on the test session, exactly as a browser would get it.
#
# Specs exercising the unauthenticated path itself (sessions_spec.rb, passwords_spec.rb)
# opt out with `skip_authentication: true` at the describe/it level.
module AuthenticationHelpers
  def sign_in_as(user)
    post session_path, params: { email: user.email, password: user.password }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request

  config.before(:each, type: :request) do
    sign_in_as(create(:user)) unless self.class.metadata[:skip_authentication]
  end
end
