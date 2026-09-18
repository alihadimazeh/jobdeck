require "rails_helper"

RSpec.describe "layouts/mailer", type: :view do
  # No real mailer exists yet (app/mailers/ has only the stock ApplicationMailer, per
  # CLAUDE.md's planned auth work) to exercise this layout through - render it directly
  # the same way ActionMailer would, so it's still covered before that lands.
  def render_mailer(body)
    ActionController::Base.render(layout: "layouts/mailer", inline: body)
  end

  it "renders the body content inside the branded shell" do
    html = render_mailer("<p>Your quote has been accepted.</p>")

    expect(html).to include("Your quote has been accepted.")
    expect(html).to include("Jobdeck")
    expect(html).to include("#EA580C") # brand accent rule
  end

  it "uses an email-safe font stack, not the self-hosted Inter font" do
    html = render_mailer("<p>Body</p>")

    expect(html).to include("Helvetica, Arial, sans-serif")
    expect(html).not_to match(/font-family:[^;]*Inter/)
  end
end
