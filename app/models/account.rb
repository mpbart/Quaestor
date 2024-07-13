# frozen_string_literal: true

class Account < ActiveRecord::Base
  belongs_to :user
  has_many :balances
  has_many :transactions

  # Account types mapped to their corresponding account sub-types
  ACCOUNT_TYPES = {
    'depository' => %w[checking savings hsa cd moeny_market paypal prepaid
                       cash_management ebt cash],
    'investment' => ['529', '401a', '401k', '403B', '457b', 'brokerage', 'cash_isa',
                     'crypto_exchange', 'education_savings_account', 'fixed_annuity',
                     'health_reimbursement_arrangement', 'hsa', 'ira', 'isa', 'life_insurance',
                     'mutual_fund', 'non-taxable_brokerage_account', 'other', 'pension', 'prif',
                     'profit_sharing_plan', 'roth', 'roth 401k', 'trust', 'ugma', 'utma'],
    'credit'     => ['credit_card'],
    'loan'       => %w[auto business commercial construction consumer home_equity
                       loan mortgage overdraft line_of_credit student other],
    'other'      => []
  }.freeze
  DEBT_ACCOUNT_TYPES = %w[credit loan].freeze

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

  BALANCES_BY_MONTH_SQL = <<-SQL
    WITH RECURSIVE months AS (
      SELECT DATE_TRUNC('month', NOW()) AS month
      UNION ALL
      SELECT month - INTERVAL '1 month'
      FROM months
      WHERE month > DATE_TRUNC('month', NOW()) - INTERVAL '12 months'
    ),
    account_months AS (
      SELECT accounts.id AS account_id, months.month
      FROM accounts
      CROSS JOIN months
      WHERE accounts.user_id = ?
    ),
    monthly_balances AS (
      SELECT
        account_id,
        DATE_TRUNC('month', created_at) as month,
        amount,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY account_id, DATE_TRUNC('month', created_at) ORDER BY created_at DESC) AS row_num
      FROM
        balances
      WHERE
        created_at >= (SELECT MIN(created_at) FROM balances) - INTERVAL '12 months'
    ),
    latest_balances AS (
      SELECT
        account_id,
        DATE_TRUNC('month', created_at) AS month,
        amount
      FROM
        monthly_balances
      WHERE
        row_num = 1
    ),
    filled_balances AS (
      SELECT
        am.account_id,
        am.month,
        COALESCE(lb.amount, LAST_VALUE(lb.amount) OVER (
          PARTITION BY am.account_id
          ORDER BY am.month
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )) AS amount
      FROM
        account_months am
      LEFT JOIN latest_balances lb
        ON am.account_id = lb.account_id
        AND am.month = lb.month
    )
    SELECT
      account_id,
      account_type,
      month,
      coalesce(amount, 0.0) AS amount
    FROM
      filled_balances fb JOIN accounts a
      ON fb.account_id = a.id
    ORDER BY
      account_id,
      month;
  SQL

  BALANCE_SQL = <<-SQL
    SELECT SUM(balances.amount) AS balance FROM accounts
    JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY created_at DESC) FROM balances)
    AS balances ON balances.account_id = accounts.id
    WHERE row_number = 1
    AND accounts.user_id = ?
    AND accounts.id IN (?)
  SQL

  def self.net_worth(user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [NET_WORTH_SQL, user_id, user_id])
    ActiveRecord::Base.connection.execute(sanitized_sql, user_id).first['net_worth']
  end

  def self.current_balance(user_id, account_ids)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array,
                                            [BALANCE_SQL, user_id, account_ids])
    ActiveRecord::Base.connection.execute(sanitized_sql).first['balance']
  end

  # TODO: Make configurable over a given time period instead of hardcoding to 12 months?
  def self.balances_by_month(user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [BALANCES_BY_MONTH_SQL, user_id])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end
end
