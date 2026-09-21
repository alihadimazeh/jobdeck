require "rails_helper"

RSpec.describe "Documents UI (Milestone 10)", type: :system do
  let(:customer) { create(:customer) }
  let(:lead)     { create(:lead, customer: customer) }

  it "uploads a document from the Documents card's inline form" do
    visit lead_path(lead)
    expect(page).to have_content("No documents yet.")

    attach_file "File", Rails.root.join("spec/fixtures/files/sample.pdf")
    fill_in "Label", with: "Site plan"
    click_button "Add Document"

    expect(page).to have_content("Site plan")
    expect(page).to have_current_path(lead_path(lead))
  end

  it "redirects back with a flash alert when uploading with no file, and creates nothing" do
    visit lead_path(lead)

    fill_in "Label", with: "No file"
    click_button "Add Document"

    expect(page).to have_content("File must be attached")
    expect(Document.count).to eq(0)
  end

  it "deletes a document via the row-actions menu" do
    document = create(:document, documentable: lead, label: "Doc to delete")
    visit lead_path(lead)

    find("button[aria-label='Actions for #{document.label}']").click
    accept_confirm do
      click_button "Delete"
    end

    expect(page).not_to have_content("Doc to delete")
    expect(page).to have_content("No documents yet.")
    expect(Document.exists?(document.id)).to be false
  end
end
