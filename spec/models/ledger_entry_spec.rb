# frozen_string_literal: true

# spec/models/ledger_entry_spec.rb

require 'rails_helper'

RSpec.describe LedgerEntry do
  subject(:ledger_entry) { build(:ledger_entry) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:order) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:entry_type) }
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:currency) }
  end

  describe 'enum' do
    it { is_expected.to define_enum_for(:entry_type).with_values(debit: 0, credit: 1, reversal: 2) }
  end

  describe 'immutability' do
    let(:entry) { create(:ledger_entry) }

    it 'prevents updates' do
      expect { entry.update!(amount_cents: 999) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'prevents destroy' do
      expect { entry.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'does not change attributes on failed update' do
      original_amount = entry.amount_cents
      begin
        entry.update!(amount_cents: 999)
      rescue ActiveRecord::ReadOnlyRecord
        # expected
      end
      expect(entry.reload.amount_cents).to eq(original_amount)
    end
  end
end
