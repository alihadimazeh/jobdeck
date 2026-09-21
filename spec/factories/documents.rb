FactoryBot.define do
  factory :document do
    documentable factory: :lead
    label { "Site plan" }
    document_type { :estimate }

    after(:build) do |document|
      document.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
        filename: "sample.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
