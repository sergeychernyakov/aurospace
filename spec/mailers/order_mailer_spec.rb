# frozen_string_literal: true

# spec/mailers/order_mailer_spec.rb

require 'rails_helper'

RSpec.describe OrderMailer do
  let(:user) { create(:user, :with_account, email: 'user@example.com', name: 'Test User') }
  let(:order) { create(:order, user: user, amount_cents: 5000) }

  describe '#order_created' do
    let(:mail) { described_class.order_created(order) }

    it 'sends to the correct recipient' do
      expect(mail.to).to eq(['user@example.com'])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq("Order ##{order.id} created")
    end

    it 'includes order amount in body' do
      expect(mail.body.encoded).to include('50.0')
    end
  end

  describe '#payment_successful' do
    let(:order) { create(:order, :successful, user: user, amount_cents: 5000) }
    let(:mail) { described_class.payment_successful(order) }

    it 'sends to the correct recipient' do
      expect(mail.to).to eq(['user@example.com'])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq("Payment for Order ##{order.id} received")
    end

    it 'includes payment info in body' do
      expect(mail.body.encoded).to include('50.0')
    end
  end

  describe '#order_cancelled' do
    let(:order) { create(:order, :cancelled, user: user, amount_cents: 5000) }
    let(:mail) { described_class.order_cancelled(order) }

    it 'sends to the correct recipient' do
      expect(mail.to).to eq(['user@example.com'])
    end

    it 'has the correct subject' do
      expect(mail.subject).to eq("Order ##{order.id} cancelled")
    end

    it 'includes cancellation info in body' do
      expect(mail.body.encoded).to include('returned to your account')
    end
  end
end
