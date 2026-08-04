class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.references :quote, null: false, foreign_key: true
      t.string  :name,   null: false
      t.decimal :length, null: false, precision: 8, scale: 2
      t.decimal :width,  null: false, precision: 8, scale: 2
      t.decimal :area,               precision: 10, scale: 2
      t.string  :notes

      t.timestamps
    end
  end
end
