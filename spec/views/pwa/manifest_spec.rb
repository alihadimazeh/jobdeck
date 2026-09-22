require "rails_helper"

RSpec.describe "pwa/manifest", type: :view do
  # The manifest route itself is commented out in config/routes.rb (Rails::Pwa's default
  # scaffold state) - rendering the template directly is the only way to exercise it.
  it "renders valid JSON with the brand theme/background colors, not the placeholder red" do
    json = ActionController::Base.render(template: "pwa/manifest", formats: [ :json ])
    parsed = JSON.parse(json)

    expect(parsed["theme_color"]).to eq("#0F172A")
    expect(parsed["background_color"]).to eq("#F8FAFC")
    expect(parsed["theme_color"]).not_to eq("red")
  end
end
