# frozen_string_literal: true

# app/controllers/accounts_controller.rb

class AccountsController < ApplicationController
  def show
    account = if params[:user_id]
                Account.find_by!(user_id: params[:user_id])
              else
                Account.find(params[:id])
              end

    render json: {
      id: account.id,
      user_id: account.user_id,
      balance_cents: account.balance_cents,
      currency: account.currency,
      ledger_entries: account.ledger_entries.order(created_at: :desc).limit(100).map { |e| ledger_entry_json(e) },
    }
  end

  private

  def ledger_entry_json(entry)
    {
      id: entry.id,
      entry_type: entry.entry_type,
      amount_cents: entry.amount_cents,
      currency: entry.currency,
      reference: entry.reference,
      order_id: entry.order_id,
      created_at: entry.created_at,
    }
  end
end
