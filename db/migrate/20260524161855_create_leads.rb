class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :title, null: false
      t.integer :status, null: false, default: 0
      t.integer :job_type, default: 0
      t.integer :source, default: 0
      t.decimal :estimated_value, precision: 10, scale: 2
      t.string :assigned_to
      t.text :description
      t.belongs_to :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
