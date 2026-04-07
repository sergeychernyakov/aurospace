# frozen_string_literal: true

# spec/models/account_spec.rb

require 'rails_helper'

RSpec.describe Account do
  subject(:account) { build(:account) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }

    it 'has_many ledger_entries (pending LedgerEntry model in PR 3)', pending: 'LedgerEntry model not yet created' do
      expect(account).to have_many(:ledger_entries).dependent(:restrict_with_error)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_numericality_of(:balance_cents).only_integer }
  end

  describe 'defaults' do
    let(:new_account) { described_class.new(user: create(:user)) }

    it 'sets balance_cents to 0' do
      expect(new_account.balance_cents).to eq(0)
    end

    it 'sets currency to RUB' do
      expect(new_account.currency).to eq('RUB')
    end
  end
end
