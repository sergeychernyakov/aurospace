# frozen_string_literal: true

# spec/requests/accounts_spec.rb

require 'rails_helper'

RSpec.describe 'Accounts' do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance_cents: 5000, currency: 'RUB') }

  describe 'GET /accounts/:id' do
    it 'returns account with balance' do
      get "/accounts/#{account.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['balance_cents']).to eq(5000)
      expect(response.parsed_body['currency']).to eq('RUB')
    end

    it 'includes ledger entries' do
      order = create(:order, user: user, amount_cents: 1000)
      create(:ledger_entry, account: account, order: order, entry_type: :credit, amount_cents: 1000)

      get "/accounts/#{account.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['ledger_entries'].size).to eq(1)
      expect(response.parsed_body['ledger_entries'].first['entry_type']).to eq('credit')
    end

    it 'returns 404 for non-existent account' do
      get '/accounts/999999'

      expect(response).to have_http_status(:not_found)
    end
  end
end
