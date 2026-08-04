class CreateQuoteLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_line_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.integer :item_type,   null: false
      t.string  :description, null: false
      t.decimal :quantity,   precision: 10, scale: 2, default: 1
      t.string  :unit
      t.decimal :unit_price, precision: 10, scale: 2, default: 0
      t.decimal :total,      precision: 10, scale: 2, default: 0

      t.timestamps
    end
  end
end
