require "rails_helper"

RSpec.describe "Documents", type: :request do
  let(:customer) { create(:customer) }
  let(:lead)     { create(:lead, customer: customer) }
  let(:pdf) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.pdf"), "application/pdf") }

  describe "POST /leads/:lead_id/documents" do
    it "creates a document on the lead and redirects to it" do
      params = { document: { label: "Site plan", document_type: "estimate", file: pdf } }
      expect { post lead_documents_path(lead), params: params }.to change(Document, :count).by(1)

      expect(response).to redirect_to(lead_path(lead))
      document = Document.last
      expect(document.documentable).to eq(lead)
      expect(document.label).to eq("Site plan")
    end

    it "re-renders the lead with a 422, the field error, and the user's input when no file is given" do
      params = { document: { label: "No file" } }
      expect { post lead_documents_path(lead), params: params }.not_to change(Document, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(lead.title)
      expect(response.body).to include("File must be attached")
      expect(response.body).to include('value="No file"')
      expect(response.body).to include("No documents yet.")
    end

    it "re-renders the lead with a 422 and the field error on a disallowed content type" do
      bad_file = Rack::Test::UploadedFile.new(
        StringIO.new("MZ\x90\x00 not a PDF"), "application/x-msdownload", original_filename: "bad.exe"
      )
      params = { document: { label: "Bad file", file: bad_file } }
      expect { post lead_documents_path(lead), params: params }.not_to change(Document, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("File must be a PDF, Excel file, JPEG, or PNG")
    end
  end

  describe "POST /jobs/:job_id/documents" do
    it "creates a document on the job and redirects to it" do
      job = create(:job, customer: customer)
      params = { document: { label: "Materials list", file: pdf } }

      expect { post job_documents_path(job), params: params }.to change(Document, :count).by(1)
      expect(response).to redirect_to(job_path(job))
      expect(Document.last.documentable).to eq(job)
    end
  end

  describe "POST /orders/:order_id/documents" do
    it "creates a document on the order and redirects to it" do
      job   = create(:job, customer: customer)
      order = create(:order, job: job, customer: customer)
      params = { document: { label: "Invoice", file: pdf } }

      expect { post order_documents_path(order), params: params }.to change(Document, :count).by(1)
      expect(response).to redirect_to(order_path(order))
      expect(Document.last.documentable).to eq(order)
    end
  end

  describe "POST /customers/:customer_id/documents" do
    it "creates a document on the customer and redirects to it" do
      params = { document: { label: "Signed contract", document_type: "contract", file: pdf } }
      expect { post customer_documents_path(customer), params: params }.to change(Document, :count).by(1)

      expect(response).to redirect_to(customer_path(customer))
      expect(Document.last.documentable).to eq(customer)
    end

    it "deletes a customer's document and redirects back to the customer" do
      document = create(:document, documentable: customer)
      expect { delete document_path(document) }.to change(Document, :count).by(-1)
      expect(response).to redirect_to(customer_path(customer))
    end
  end

  describe "DELETE /documents/:id" do
    it "destroys the document and redirects to its parent" do
      document = create(:document, documentable: lead)

      expect { delete document_path(document) }.to change(Document, :count).by(-1)
      expect(response).to redirect_to(lead_path(lead))
      expect(response).to have_http_status(:see_other)
    end
  end

  describe "inline rendering on the parent's show page" do
    it "tells the user the accepted types and size limit up front, and filters the file picker" do
      get lead_path(lead)
      field = Nokogiri::HTML(response.body).at_css("input[type='file'][name='document[file]']")

      expect(field["required"]).to be_present
      expect(field["accept"].split(",")).to include("application/pdf", ".xlsx", "image/png")
      expect(field["aria-describedby"]).to eq("document_file_hint")
      expect(response.body).to match(%r{id="document_file_hint"[^>]*>\s*PDF, Excel \(XLS/XLSX\), JPEG, or PNG &middot; up to 50 MB})
    end

    it "shows the empty state when there are no documents, and the document once one exists" do
      get lead_path(lead)
      expect(response.body).to include("No documents yet.")

      document = create(:document, documentable: lead, label: "Called it Plan A")
      get lead_path(lead)

      expect(response.body).not_to include("No documents yet.")
      expect(response.body).to include("Called it Plan A")
      expect(response.body).to include(%(id="#{ActionView::RecordIdentifier.dom_id(document)}"))
    end

    it "gives a PDF an inline View link that opens in a new tab" do
      document = create(:document, documentable: lead)
      get lead_path(lead)

      expect(response.body).to include(">View<")
      expect(response.body).to include('target="_blank"')
      expect(response.body).to match(%r{disposition=inline})
    end

    it "gives a photo a lazy thumbnail and an inline View link" do
      document = build(:document, documentable: lead, label: "Site photo")
      document.file.attach(
        io: StringIO.new("\x89PNG\r\n\x1a\n fake png data"),
        filename: "photo.png",
        content_type: "image/png"
      )
      document.save!

      get lead_path(lead)
      row = Nokogiri::HTML(response.body).at_css("##{ActionView::RecordIdentifier.dom_id(document)}")

      expect(row.at_css("img[loading='lazy'][alt='']")["src"]).to include("photo.png")
      view = row.at_css("a[aria-label='View Site photo (opens in a new tab)']")
      expect(view.text).to eq("View")
      expect(view["target"]).to eq("_blank")
      expect(view["href"]).to include("disposition=inline")
      expect(row.text).not_to include("Download")
    end

    it "gives a non-viewable file (Excel) a normal Download link instead" do
      document = build(:document, documentable: lead)
      document.file.attach(
        io: StringIO.new("PK\x03\x04 fake xlsx"),
        filename: "takeoff.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
      document.save!

      get lead_path(lead)

      expect(response.body).to include(">Download<")
      expect(response.body).not_to include(">View<")
      expect(response.body).not_to include("<img")
      expect(response.body).to match(%r{disposition=attachment})
    end
  end
end
