class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :documentable, polymorphic: true, null: false
      t.string :label
      t.string :document_type
      t.string :uploaded_by
      t.text   :description

      t.timestamps
    end
  end
end
