class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_many :accounts
  has_many :transactions, through: :accounts
  has_many :plaid_credentials

  # Only show 50 transactions at a time
  def paginated_transactions(page_num:)
    transactions.paginate(page: page_num, per_page: 50)
  end

end
