# frozen_string_literal: true

# app/admin/ledger_entries.rb

ActiveAdmin.register LedgerEntry do
  menu priority: 4

  includes :account, :order

  actions :index, :show

  index do
    id_column
    column :account
    column :order
    column :entry_type do |entry|
      entry_color = { 'credit' => 'green', 'debit' => 'orange', 'reversal' => 'red' }
      status_tag entry.entry_type, class: entry_color[entry.entry_type]
    end
    column :amount do |entry|
      number_to_currency(entry.amount_cents / 100.0, unit: '', precision: 2) + " #{entry.currency}"
    end
    column :reference
    column :created_at
    actions
  end

  filter :account
  filter :order
  filter :entry_type, as: :select, collection: LedgerEntry.entry_types
  filter :created_at

  show do
    attributes_table do
      row :id
      row :account
      row :order
      row :entry_type do |entry|
        entry_color = { 'credit' => 'green', 'debit' => 'orange', 'reversal' => 'red' }
        status_tag entry.entry_type, class: entry_color[entry.entry_type]
      end
      row :amount do |entry|
        number_to_currency(entry.amount_cents / 100.0, unit: '', precision: 2) + " #{entry.currency}"
      end
      row :reference
      row :metadata
      row :created_at
    end
  end
end
