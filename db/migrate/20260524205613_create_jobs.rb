class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.string :title, null: false
      t.integer :status, null: false, default: 0
      t.integer :job_type, default: 0
      t.decimal :estimated_value, precision: 10, scale: 2
      t.string :assigned_to
      t.date :start_date
      t.date :end_date
      t.text :description
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :province
      t.string :postal_code
      t.belongs_to :customer, null: true, foreign_key: true
      t.belongs_to :lead, null: true, foreign_key: true

      t.timestamps
    end
  end
end
