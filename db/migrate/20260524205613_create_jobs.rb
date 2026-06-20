class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.string :title, null: false
      t.integer :status, null: false, default: 0
      t.integer :job_type, default: 0
      t.string :source
      t.decimal :estimated_value
      t.string :assigned_to
      t.text :description
      t.belongs_to :customer, null: false, foreign_key: true
      t.belongs_to :lead, null: true, foreign_key: true

      t.timestamps
    end
  end
end
