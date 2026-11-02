# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  belongs_to :owner, class_name: 'User', optional: true, inverse_of: :members
  has_many :members, class_name: 'User', foreign_key: :owner_id, inverse_of: :owner,
                     dependent: :restrict_with_error

  validate :owner_must_be_household_owner

  has_many :accounts
  has_many :transactions
  has_many :plaid_credentials
  has_many_attached :transaction_csvs
  has_one :google_drive_credential

  def member?
    owner_id.present?
  end

  def data_owner
    owner || self
  end

  # Only show 50 transactions at a time
  def paginated_transactions(page_num:, where_clause: '1=1')
    transactions.where(where_clause).by_date.paginate(page: page_num, per_page: 50)
  end

  private

  def owner_must_be_household_owner
    return unless owner

    errors.add(:owner, 'cannot be yourself') if owner == self
    errors.add(:owner, 'cannot be a member') if owner.member?
    errors.add(:owner, 'cannot be assigned while you have members') if members.exists?
  end
end
