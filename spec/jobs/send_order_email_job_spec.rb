# frozen_string_literal: true

# spec/jobs/send_order_email_job_spec.rb

require 'rails_helper'

RSpec.describe SendOrderEmailJob do
  let(:user) { create(:user, :with_account) }
  let(:order) { create(:order, user: user, amount_cents: 5000) }

  describe '#perform' do
    it 'sends the email' do
      expect {
        described_class.perform_now(order.id, 'order_created')
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'creates a NotificationLog' do
      expect {
        described_class.perform_now(order.id, 'order_created')
      }.to change(NotificationLog, :count).by(1)

      log = NotificationLog.last
      expect(log.order).to eq(order)
      expect(log.mail_type).to eq('order_created')
      expect(log.recipient).to eq(user.email)
      expect(log.sent_at).to be_present
    end

    it 'skips duplicate email when NotificationLog exists' do
      create(:notification_log, order: order, mail_type: 'order_created', recipient: user.email)

      expect {
        described_class.perform_now(order.id, 'order_created')
      }.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'does not create duplicate NotificationLog' do
      create(:notification_log, order: order, mail_type: 'order_created', recipient: user.email)

      expect {
        described_class.perform_now(order.id, 'order_created')
      }.not_to change(NotificationLog, :count)
    end

    it 'sends payment_successful email' do
      expect {
        described_class.perform_now(order.id, 'payment_successful')
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'sends order_cancelled email' do
      expect {
        described_class.perform_now(order.id, 'order_cancelled')
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
