# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'household ownership' do
    let(:owner) { create(:user) }
    let(:member) { create(:user, :member, owner: owner) }

    it 'uses an owner’s own data' do
      expect(owner).not_to be_member
      expect(owner.data_owner).to eq(owner)
    end

    it 'uses the household owner’s data for a member' do
      expect(member).to be_member
      expect(member.data_owner).to eq(owner)
      expect(owner.members).to include(member)
    end

    context 'with a member as owner' do
      let(:nested_member) { build(:user, owner: member) }

      it 'rejects ownership chains' do
        expect(nested_member).not_to be_valid
        expect(nested_member.errors[:owner]).to include('cannot be a member')
      end
    end

    context 'with self-ownership' do
      before { owner.owner = owner }

      it 'rejects self-ownership' do
        expect(owner).not_to be_valid
        expect(owner.errors[:owner]).to include('cannot be yourself')
      end
    end

    context 'when an owner already has members' do
      let(:other_owner) { create(:user) }

      before do
        member
        owner.owner = other_owner
      end

      it 'does not allow the owner to become a member' do
        expect(owner).not_to be_valid
        expect(owner.errors[:owner]).to include('cannot be assigned while you have members')
      end
    end

    context 'when deleting an owner with members' do
      before { member }

      it 'does not leave members without an owner' do
        expect { owner.destroy }.not_to(change(User, :count))
        expect(member.reload.data_owner).to eq(owner)
      end
    end
  end
end
