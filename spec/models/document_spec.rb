require "rails_helper"

RSpec.describe Document, type: :model do
  describe "validations" do
    it "is valid with an attached PDF" do
      expect(build(:document)).to be_valid
    end

    it "is invalid with a disallowed content type" do
      # Active Storage sniffs the actual bytes (via Marcel) rather than trusting the
      # declared content_type: - reusing the sample.pdf fixture here (real PDF magic
      # bytes) would just get correctly re-detected as a valid PDF no matter what
      # content_type/filename is claimed. Needs bytes that actually aren't PDF-shaped.
      document = Document.new(documentable: create(:lead), label: "test", document_type: :estimate)
      document.file.attach(
        io: StringIO.new("MZ\x90\x00 not a PDF"),
        filename: "sample.exe",
        content_type: "application/x-msdownload"
      )

      expect(document).not_to be_valid
      expect(document.errors[:file]).to include("must be a PDF, Excel file, JPEG, or PNG")
    end

    it "is invalid when the file is over 50MB" do
      document = build(:document)
      allow(document.file.blob).to receive(:byte_size).and_return(51.megabytes)

      expect(document).not_to be_valid
      expect(document.errors[:file]).to include("must be smaller than 50MB")
    end

    it "is invalid with no file attached" do
      document = build(:document)
      document.file.detach

      expect(document).not_to be_valid
      expect(document.errors[:file]).to include("must be attached")
    end
  end

  describe "document_type enum" do
    it "backs document_type with the estimate | invoice | plan | contract | photo | other values" do
      expect(described_class.document_types).to eq(
        "estimate" => "estimate", "invoice" => "invoice", "plan" => "plan",
        "contract" => "contract", "photo" => "photo", "other" => "other"
      )
    end

    it "exposes suffixed predicates (suffix: true)" do
      document = build(:document, document_type: :contract)
      expect(document.contract_document_type?).to be true
    end
  end

  it "belongs to a polymorphic documentable" do
    reflection = described_class.reflect_on_association(:documentable)
    expect(reflection.macro).to eq(:belongs_to)
    expect(reflection.options[:polymorphic]).to be true
  end

  it "attaches to whichever documentable it's given" do
    lead = create(:lead)
    document = create(:document, documentable: lead)
    expect(document.documentable).to eq(lead)
    expect(document.documentable_type).to eq("Lead")
  end
end
