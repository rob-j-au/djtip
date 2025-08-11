require 'rails_helper'

RSpec.describe Tip, type: :model do
  describe 'validations' do
    it 'validates presence of amount' do
      tip = build(:tip, amount: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:amount]).to include("can't be blank")
    end

    it 'validates presence of currency' do
      tip = build(:tip, currency: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:currency]).to include("can't be blank")
    end

    it 'validates presence of event' do
      tip = build(:tip, event: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:event]).to include("can't be blank")
    end

    it 'validates presence of user' do
      tip = build(:tip, user: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:user]).to include("can't be blank")
    end

    it 'validates numericality of amount' do
      tip = build(:tip, amount: 0)
      expect(tip).not_to be_valid
      expect(tip.errors[:amount]).to include("must be greater than 0")
    end
  end

  describe 'relationships' do
    it 'belongs to event' do
      tip = build(:tip)
      expect(tip.event).to be_present
    end

    it 'belongs to user' do
      tip = build(:tip)
      expect(tip.user).to be_present
    end
  end

  describe 'scopes' do
    let!(:event) { create(:event) }
    let!(:user) { create(:user) }
    let!(:old_tip) { create(:tip, event: event, user: user, created_at: 2.days.ago) }
    let!(:new_tip) { create(:tip, event: event, user: user, created_at: 1.day.ago) }
    let!(:large_tip) { create(:tip, :large_amount, event: event, user: user) }
    let!(:small_tip) { create(:tip, amount: 5.00, event: event, user: user) }

    describe '.recent' do
      it 'orders tips by created_at descending' do
        expect(Tip.recent.to_a).to eq([large_tip, small_tip, new_tip, old_tip])
      end
    end

    describe '.by_amount' do
      it 'orders tips by amount descending' do
        expect(Tip.by_amount.to_a).to eq([large_tip, new_tip, old_tip, small_tip])
      end
    end
  end

  describe '#formatted_amount' do
    it 'returns formatted amount with currency' do
      tip = build(:tip, amount: 25.50, currency: 'USD')
      expect(tip.formatted_amount).to eq('USD 25.5')
    end

    it 'works with different currencies' do
      tip = build(:tip, :with_euro_currency)
      expect(tip.formatted_amount).to eq('EUR 20.0')
    end
  end

  describe 'factory' do
    it 'creates a valid tip' do
      tip = build(:tip)
      expect(tip).to be_valid
    end

    it 'creates a tip with large amount trait' do
      tip = build(:tip, :large_amount)
      expect(tip.amount).to eq(100.00)
    end

    it 'creates a tip without message trait' do
      tip = build(:tip, :without_message)
      expect(tip.message).to be_nil
    end
  end

  describe 'invalid tip' do
    it 'is invalid without amount' do
      tip = build(:tip, amount: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:amount]).to include("can't be blank")
    end

    it 'is invalid with zero amount' do
      tip = build(:tip, amount: 0)
      expect(tip).not_to be_valid
      expect(tip.errors[:amount]).to include("must be greater than 0")
    end

    it 'is invalid with negative amount' do
      tip = build(:tip, amount: -10)
      expect(tip).not_to be_valid
      expect(tip.errors[:amount]).to include("must be greater than 0")
    end

    it 'is invalid without currency' do
      tip = build(:tip, currency: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:currency]).to include("can't be blank")
    end

    it 'is invalid without event' do
      tip = build(:tip, event: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:event]).to include("can't be blank")
    end

    it 'is invalid without user' do
      tip = build(:tip, user: nil)
      expect(tip).not_to be_valid
      expect(tip.errors[:user]).to include("can't be blank")
    end
  end
end
