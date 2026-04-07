# frozen_string_literal: true

# spec/models/webhook_event_spec.rb

require 'rails_helper'

RSpec.describe WebhookEvent do
  subject(:webhook_event) { build(:webhook_event) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:external_event_id) }
    it { is_expected.to validate_uniqueness_of(:external_event_id) }
    it { is_expected.to validate_presence_of(:event_type) }
  end

  describe 'uniqueness of external_event_id' do
    it 'prevents duplicate external_event_id' do
      create(:webhook_event, external_event_id: 'duplicate_id')
      duplicate = build(:webhook_event, external_event_id: 'duplicate_id')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_event_id]).to include('has already been taken')
    end
  end

  describe 'defaults' do
    it 'sets status to pending' do
      event = described_class.new(
        provider: 'yookassa',
        external_event_id: 'test_1',
        event_type: 'payment.succeeded',
      )
      expect(event.status).to eq('pending')
    end

    it 'sets payload to empty hash' do
      event = described_class.new(
        provider: 'yookassa',
        external_event_id: 'test_2',
        event_type: 'payment.succeeded',
      )
      expect(event.payload).to eq({})
    end
  end
end
