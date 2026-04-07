# frozen_string_literal: true

# db/migrate/20260407100002_create_orders.rb

class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: 'RUB'
      t.integer :status, null: false, default: 0
      t.string :payment_provider
      t.string :external_payment_id
      t.datetime :paid_at
      t.datetime :cancelled_at
      t.timestamps
    end

    add_index :orders, :status
    add_check_constraint :orders, 'amount_cents > 0', name: 'orders_amount_cents_positive'
  end
end
