class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.string :address
      # t.references :lead, null: false, foreign_key: true
      # t.references :job, null: false, foreign_key: true

      t.timestamps
    end
  end
end
=begin
id
first_name        string, null: false
last_name         string, null: false
email             string
phone             string
address_line1     string
address_line2     string
city              string
state             string
zip               string
status            string, default: "active"
notes             text
created_at
updated_at
=end