# frozen_string_literal: true

# db/migrate/20260407100005_create_notification_logs.rb

class CreateNotificationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_logs do |t|
      t.references :order, null: false, foreign_key: true, index: false
      t.string :mail_type, null: false
      t.string :recipient, null: false
      t.datetime :sent_at
      t.timestamps
    end

    add_index :notification_logs, [:order_id, :mail_type], unique: true
  end
end
