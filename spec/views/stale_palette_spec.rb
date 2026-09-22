require "rails_helper"

# Files outside the Tailwind pipeline (mail layouts, the PWA manifest, helpers) hardcode
# colors, so the navy+blue retint (PR #42) couldn't reach them automatically. Guard against
# the old "industrial slate + safety orange" values creeping back anywhere.
RSpec.describe "Theme palette" do
  it "has no pre-retint hex values left in views or helpers" do
    stale_hexes = %w[#EA580C #1E293B]
    offenders = Rails.root.glob("app/{views,helpers}/**/*").select(&:file?).select do |path|
      text = path.read
      stale_hexes.any? { |hex| text.match?(/#{Regexp.escape(hex)}/i) }
    end

    expect(offenders.map { |p| p.relative_path_from(Rails.root).to_s }).to eq([])
  end
end
