class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.references :lead,     null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.string  :quote_number
      t.decimal :subtotal,  precision: 10, scale: 2, default: 0
      t.decimal :tax_rate,  precision: 5,  scale: 4, default: 0
      t.decimal :total,     precision: 10, scale: 2, default: 0
      t.date    :issued_date
      t.date    :valid_until
      t.text    :notes

      t.timestamps
    end

    add_index :quotes, :quote_number, unique: true
  end
end
