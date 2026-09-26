class Document < ApplicationRecord
  ACCEPTED_TYPES = %w[
    application/pdf
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    image/jpeg
    image/png
  ].freeze
  MAX_SIZE = 50.megabytes
  # For the upload field's `accept` - some OSes map XLS/XLSX MIME types unreliably.
  ACCEPTED_EXTENSIONS = %w[.pdf .xls .xlsx .jpg .jpeg .png].freeze

  belongs_to :documentable, polymorphic: true
  has_one_attached :file

  enum :document_type, {
    estimate: "estimate",
    invoice:  "invoice",
    plan:     "plan",
    contract: "contract",
    photo:    "photo",
    other:    "other"
  }, suffix: true

  validate :acceptable_file

  private

  def acceptable_file
    unless file.attached?
      errors.add(:file, "must be attached")
      return
    end

    unless ACCEPTED_TYPES.include?(file.content_type)
      errors.add(:file, "must be a PDF, Excel file, JPEG, or PNG")
    end

    if file.blob.byte_size > MAX_SIZE
      errors.add(:file, "must be smaller than 50MB")
    end
  end
end
