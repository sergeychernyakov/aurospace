# frozen_string_literal: true

# db/migrate/20260407200000_add_discarded_at_to_models.rb

class AddDiscardedAtToModels < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_column :orders, :discarded_at, :datetime
      add_column :users, :discarded_at, :datetime
      add_column :accounts, :discarded_at, :datetime
      add_column :webhook_events, :discarded_at, :datetime
      add_column :notification_logs, :discarded_at, :datetime
    end

    add_index :orders, :discarded_at, algorithm: :concurrently
    add_index :users, :discarded_at, algorithm: :concurrently
    add_index :accounts, :discarded_at, algorithm: :concurrently
    add_index :webhook_events, :discarded_at, algorithm: :concurrently
    add_index :notification_logs, :discarded_at, algorithm: :concurrently
  end
end
