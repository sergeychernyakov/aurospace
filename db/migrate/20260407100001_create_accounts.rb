# frozen_string_literal: true

# db/migrate/20260407100001_create_accounts.rb

class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :balance_cents, null: false, default: 0
      t.string :currency, null: false, default: 'RUB'
      t.timestamps
    end
  end
end
