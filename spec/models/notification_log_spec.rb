# frozen_string_literal: true

# spec/models/notification_log_spec.rb

require 'rails_helper'

RSpec.describe NotificationLog do
  subject(:notification_log) { build(:notification_log) }

  describe 'associations' do
    it { is_expected.to belong_to(:order) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:mail_type) }
    it { is_expected.to validate_presence_of(:recipient) }
  end

  describe 'uniqueness of (order_id, mail_type)' do
    it 'prevents duplicate mail_type for the same order' do
      order = create(:order)
      create(:notification_log, order: order, mail_type: 'order_confirmation')
      duplicate = build(:notification_log, order: order, mail_type: 'order_confirmation')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:mail_type]).to include('has already been taken')
    end

    it 'allows same mail_type for different orders' do
      create(:notification_log, mail_type: 'order_confirmation')
      other = build(:notification_log, mail_type: 'order_confirmation')
      expect(other).to be_valid
    end
  end
end
