class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_many :accounts
  has_many :transactions
  has_many :plaid_credentials
  has_many_attached :transaction_csvs

  # Only show 50 transactions at a time
  def paginated_transactions(page_num:)
    transactions.by_date.paginate(page: page_num, per_page: 50)
  end
end
