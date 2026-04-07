# frozen_string_literal: true

# spec/models/user_spec.rb

require 'rails_helper'

RSpec.describe User do
  subject(:user) { build(:user) }

  describe 'associations' do
    it { is_expected.to have_one(:account).dependent(:destroy) }

    it { is_expected.to have_many(:orders).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to allow_value('user@example.com').for(:email) }
    it { is_expected.not_to allow_value('invalid-email').for(:email) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
