# frozen_string_literal: true

# db/migrate/20260407100003_create_ledger_entries.rb

class CreateLedgerEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :ledger_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.integer :entry_type, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: 'RUB'
      t.string :reference
      t.jsonb :metadata, default: {}
      t.timestamps
    end
  end
end
