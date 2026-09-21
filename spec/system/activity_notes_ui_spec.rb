require "rails_helper"

RSpec.describe "ActivityNotes UI (Milestone 4 - Turbo Frames)", type: :system do
  let(:customer) { create(:customer) }
  let(:lead)     { create(:lead, customer: customer) }

  it "adds a note from the Activity card's inline form, without leaving the page" do
    visit lead_path(lead)
    expect(page).to have_content("No activity yet.")

    fill_in "Note", with: "Called the customer, they're happy with progress."
    click_button "Add Note"

    expect(page).to have_content("Called the customer, they're happy with progress.")
    expect(page).to have_current_path(lead_path(lead))
  end

  it "edits a note in place via its Turbo Frame, with no page navigation" do
    note = lead.activity_notes.create!(body: "Original body", author: "Jane")
    visit lead_path(lead)

    find("button[aria-label='Actions for #{note.body}']").click
    within "#activity_note_#{note.id}" do
      click_link "Edit"
      expect(page).to have_field("Note", with: "Original body")

      fill_in "Note", with: "Updated body"
      click_button "Save"
    end

    expect(page).to have_content("Updated body")
    expect(page).not_to have_content("Original body")
    # A frame-scoped update never navigates - still the same URL, no full page load.
    expect(page).to have_current_path(lead_path(lead))
  end

  it "shows the validation error in place when editing with a blank body" do
    note = lead.activity_notes.create!(body: "Original body")
    visit lead_path(lead)

    find("button[aria-label='Actions for #{note.body}']").click
    within "#activity_note_#{note.id}" do
      click_link "Edit"
      fill_in "Note", with: ""
      click_button "Save"
    end

    expect(page).to have_content("Body can't be blank")
    expect(page).to have_field("Note", with: "")
    expect(note.reload.body).to eq("Original body")
  end

  it "deletes a note via the row-actions menu, escaping its Turbo Frame correctly" do
    note = lead.activity_notes.create!(body: "Note to delete")
    visit lead_path(lead)

    find("button[aria-label='Actions for #{note.body}']").click
    accept_confirm do
      click_button "Delete"
    end

    expect(page).not_to have_content("Note to delete")
    expect(page).to have_content("No activity yet.")
    expect(ActivityNote.exists?(note.id)).to be false
  end
end
