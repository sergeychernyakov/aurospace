# frozen_string_literal: true

# app/admin/accounts.rb

ActiveAdmin.register Account do
  menu priority: 3

  includes :user

  scope_to(nil, association_method: :unscoped)
  controller do
    def scoped_collection
      Account.unscoped.includes(:user)
    end
  end

  index do
    id_column
    column :user do |account|
      account.user&.email
    end
    column :balance do |account|
      number_to_currency(account.balance_cents / 100.0, unit: '', precision: 2) + " #{account.currency}"
    end
    column :currency
    column :created_at
    actions
  end

  filter :user
  filter :balance_cents
  filter :currency

  show do
    attributes_table do
      row :id
      row :user do |account|
        account.user&.email
      end
      row :balance do |account|
        number_to_currency(account.balance_cents / 100.0, unit: '', precision: 2) + " #{account.currency}"
      end
      row :currency
      row :discarded_at
      row :created_at
      row :updated_at
    end

    panel 'Ledger Entries' do
      table_for account.ledger_entries.order(created_at: :desc).limit(50) do
        column :id
        column :order_id
        column :entry_type do |entry|
          entry_color = { 'credit' => 'green', 'debit' => 'orange', 'reversal' => 'red' }
          status_tag entry.entry_type, class: entry_color[entry.entry_type]
        end
        column :amount do |entry|
          number_to_currency(entry.amount_cents / 100.0, unit: '', precision: 2) + " #{entry.currency}"
        end
        column :reference
        column :created_at
      end
    end
  end
end
