class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :job, null: false, foreign_key: true
      t.references :lead, null: true, foreign_key: true
      t.integer   :status, null: false, default: 0  # enum
      t.string    :order_number # auto-generated ORD-2024-0001
      t.decimal :subtotal,  precision: 10, scale: 2, default: 0
      t.decimal :tax_rate,  precision: 5,  scale: 4, default: 0
      t.decimal :total,     precision: 10, scale: 2, default: 0
      t.date :issued_date
      t.date :due_date
      t.text :notes

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
  end
end
