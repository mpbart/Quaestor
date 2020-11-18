class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_many :accounts
  has_many :transactions, through: :accounts
  has_many :split_transactions, through: :transactions
  has_many :plaid_credentials

  # Only show 50 transactions at a time
  def paginated_transactions(page_num:)
    t = transactions.by_date.paginate(page: page_num, per_page: 45)
    s = split_transactions.by_date.where('split_transactions.date BETWEEN ? AND ?', t.last.date, t.first.date)
    (t + s).sort_by{ |i| i.date }
  end

end
