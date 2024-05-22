# frozen_string_literal: true

class Account < ActiveRecord::Base
  belongs_to :user
  has_many :balances
  has_many :transactions

  # Account types mapped to their corresponding account sub-types
  ACCOUNT_TYPES = {
    'depository' => %w[checking savings hsa cd moeny_market paypal prepaid
                       cash_management ebt cash],
    'credit'     => ['credit_card'],
    'loan'       => %w[auto business commercial construction consumer home_equity
                       loan mortgage overdraft line_of_credit student other],
    'investment' => ['529', '401a', '401k', '403B', '457b', 'brokerage', 'cash_isa',
                     'crypto_exchange', 'education_savings_account', 'fixed_annuity',
                     'health_reimbursement_arrangement', 'hsa', 'ira', 'isa', 'life_insurance',
                     'mutual_fund', 'non-taxable_brokerage_account', 'other', 'pension', 'prif',
                     'profit_sharing_plan', 'roth', 'roth 401k', 'trust', 'ugma', 'utma'],
    'other'      => []
  }.freeze

  NET_WORTH_SQL = <<-SQL
    WITH debts AS (
      SELECT SUM(balances.amount) FROM accounts
      JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY created_at DESC) FROM balances)
      AS balances ON balances.account_id = accounts.id
      WHERE row_number = 1 AND accounts.account_type IN ('loan', 'credit')
      AND accounts.user_id = ?
      ),
    assets AS (
      SELECT SUM(balances.amount) FROM accounts
      JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY created_at DESC) FROM balances)
      AS balances ON balances.account_id = accounts.id
      WHERE row_number = 1 AND accounts.account_type IN ('depository', 'investment')
      AND accounts.user_id = ?
    )
    SELECT assets.sum - debts.sum AS net_worth FROM assets, debts
  SQL

  def self.net_worth(user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [NET_WORTH_SQL, user_id, user_id])
    ActiveRecord::Base.connection.execute(sanitized_sql, user_id).first['net_worth']
  end
end
