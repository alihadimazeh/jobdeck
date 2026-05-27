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
      t.belongs_to :customer, foreign_key: true
      # t.references :customer, null: false, foreign_key: true
      # t.references :job, null: false, foreign_key: true

      t.timestamps
    end
  end
end

=begin
id
customer_id       integer, null: false, foreign key
title             string, null: false
status            string, null: false, default: "new"
                  # new | contacted | quoted | converted | lost
job_type          string
                  # tile | flooring | materials | mixed
source            string
                  # walk_in | phone | referral | website | other
estimated_value   decimal, precision: 10, scale: 2
assigned_to       string
follow_up_date    date
description       text
created_at
updated_at
=end
