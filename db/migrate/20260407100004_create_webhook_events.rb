# frozen_string_literal: true

# db/migrate/20260407100004_create_webhook_events.rb

class CreateWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :webhook_events do |t|
      t.string :provider, null: false
      t.string :external_event_id, null: false
      t.string :event_type, null: false
      t.jsonb :payload, default: {}
      t.datetime :processed_at
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end

    add_index :webhook_events, :external_event_id, unique: true
    add_index :webhook_events, :provider
  end
end
