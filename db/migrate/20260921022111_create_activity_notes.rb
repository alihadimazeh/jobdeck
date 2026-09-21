class CreateActivityNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_notes do |t|
      t.references :notable, polymorphic: true, null: false
      t.text    :body,   null: false
      t.string  :author
      t.boolean :pinned, null: false, default: false

      t.timestamps
    end
  end
end
