require "rails_helper"

RSpec.describe "shared/_table", type: :view do
  it "renders a header per column and yields the tbody rows" do
    render "shared/table", { columns: [ "Name", "Status" ] } do
      "<tr><td>Ada</td></tr>".html_safe
    end
    expect(rendered).to have_selector("div.overflow-x-auto table.table")
    expect(rendered).to have_selector("thead th", text: "Name")
    expect(rendered).to have_selector("thead th", text: "Status")
    expect(rendered).to have_selector("tbody tr td", text: "Ada")
  end

  it "accepts hash columns with an alignment" do
    render "shared/table", { columns: [ { label: "Total", align: "right" } ] } do
      "".html_safe
    end
    expect(rendered).to have_selector("th.text-right", text: "Total")
  end

  it "renders no tfoot when footer is not given" do
    render "shared/table", { columns: [ "Name" ] } do
      "".html_safe
    end
    expect(rendered).not_to have_selector("tfoot")
  end

  it "renders the given footer row inside a tfoot, separate from tbody" do
    footer = "<tr><td>Total</td><td>$10</td></tr>".html_safe
    render "shared/table", { columns: [ "Name", "Amount" ], footer: footer } do
      "<tr><td>Row</td><td>$5</td></tr>".html_safe
    end
    expect(rendered).to have_selector("tfoot tr td", text: "Total")
    expect(rendered).to have_selector("tbody tr td", text: "Row")
    expect(rendered).not_to have_selector("tbody", text: "Total")
  end
end
