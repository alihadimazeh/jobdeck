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
      t.belongs_to :customer, foreign_key: true
      t.belongs_to :lead, null: true, foreign_key: true
      # t.references :customer, null: false, foreign_key: true
      # t.references :lead, null: true, foreign_key: true

      t.timestamps
    end
  end
end
=begin
id
customer_id       integer, null: false, foreign key
lead_id           integer, foreign key (nullable)
title             string, null: false
status            integer, null: false, default: 0: "active"
                  # active | on_hold | completed | cancelled
job_type          integer, default: 0 # mixed: 0
                  # tile | flooring | materials | kitchen | mixed
start_date        date
end_date          date
description       text
address_line1     string
city              string
state             string
zip               string
created_at
updated_at
=end
