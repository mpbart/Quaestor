# frozen_string_literal: true

class Transaction < ApplicationRecord
  acts_as_paranoid

  belongs_to :account, optional: true
  belongs_to :user
  belongs_to :transaction_group, primary_key: :uuid, foreign_key: :transaction_group_uuid,
optional: true
  belongs_to :plaid_category
  has_and_belongs_to_many :labels

  scope :by_date, -> { order('transactions.date DESC').order('transactions.description DESC') }
  scope :within_days, lambda { |start_date, end_date|
                        where('transactions.date BETWEEN ? AND ?', start_date, end_date)
                      }

  TOTAL_PER_MONTH_SQL = <<-SQL.freeze
    SELECT SUM(amount) as total, DATE_TRUNC('MONTH', t.date) AS month
    FROM transactions t
    JOIN accounts a
    ON t.account_id = a.id
    JOIN plaid_categories pc
    ON t.plaid_category_id = pc.id
    AND a.user_id = ?
    AND pc.primary_category %s 'INCOME'
    AND pc.detailed_category NOT IN (#{::PlaidCategory::EXCLUDED_CATEGORIES.map { |i| "'#{i}'" }.join(', ')})
    AND t.deleted_at IS NULL
    GROUP BY DATE_TRUNC('MONTH', t.date)
    ORDER BY month ASC
  SQL

  CUMULATIVE_TOTALS_SQL = <<-SQL
    SELECT SUM(amount) as total, primary_category
    FROM transactions t
    JOIN accounts a
    ON t.account_id = a.id
    JOIN plaid_categories pc
    ON t.plaid_category_id = pc.id
    AND a.user_id = ?
    AND t.deleted_at IS NULL
    GROUP BY primary_category
  SQL

  PRIMARY_CATEGORY_PER_MONTH_SQL = <<-SQL
    SELECT SUM(amount) as total, DATE_TRUNC('MONTH', t.date) AS month
    FROM transactions t
    JOIN accounts a
    ON t.account_id = a.id
    JOIN plaid_categories pc
    ON t.plaid_category_id = pc.id
    AND a.user_id = ?
    AND pc.primary_category = ?
    AND t.deleted_at IS NULL
    GROUP BY DATE_TRUNC('MONTH', t.date)
    ORDER BY month ASC
  SQL

  DETAILED_CATEGORY_PER_MONTH_SQL = <<-SQL
    SELECT SUM(amount) as total, DATE_TRUNC('MONTH', t.date) AS month
    FROM transactions t
    JOIN accounts a
    ON t.account_id = a.id
    JOIN plaid_categories pc
    ON t.plaid_category_id = pc.id
    AND a.user_id = ?
    AND pc.detailed_category = ?
    AND t.deleted_at IS NULL
    GROUP BY DATE_TRUNC('MONTH', t.date)
    ORDER BY month ASC
  SQL

  MERCHANT_PER_MONTH_SQL = <<-SQL
    SELECT SUM(amount) as total, DATE_TRUNC('MONTH', t.date) AS month
    FROM transactions t
    JOIN accounts a
    ON t.account_id = a.id
    AND a.user_id = ?
    AND (t.merchant_name ILIKE ? OR t.description ILIKE ?)
    AND t.deleted_at IS NULL
    GROUP BY DATE_TRUNC('MONTH', t.date)
    ORDER BY month ASC
  SQL

  LABEL_PER_MONTH_SQL = <<-SQL
    SELECT SUM(amount) as total, DATE_TRUNC('MONTH', t.date) AS month
    FROM transactions t
    JOIN accounts a
    ON t.account_id = a.id
    JOIN labels_transactions lt
    ON lt.transaction_id = t.id 
    JOIN labels l
    ON lt.label_id = l.id
    WHERE a.user_id = ?
    AND l.id = ?
    AND t.deleted_at IS NULL
    GROUP BY DATE_TRUNC('MONTH', t.date)
    ORDER BY month ASC
  SQL

  def grouped_transactions
    transaction_group&.transactions&.where&.not(id: id) || []
  end

  def self.search_by_label_name(user, label_name, page_num)
    joins(:labels).where(
      labels: { name: label_name }
    ).where(user_id: user.id)
                  .by_date
                  .paginate(page: page_num, per_page: 50)
                  .includes(:account, :plaid_category)
  end

  def self.total_spending_over_time(user_id)
    sql_statement = format(TOTAL_PER_MONTH_SQL, '<>')
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql_statement, user_id])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end

  def self.total_income_over_time(user_id)
    sql_statement = format(TOTAL_PER_MONTH_SQL, '=')
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql_statement, user_id])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end

  def self.category_totals(user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [CUMULATIVE_TOTALS_SQL, user_id])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end

  def self.primary_category_spending_over_time(category_id, user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array,
                                            [PRIMARY_CATEGORY_PER_MONTH_SQL, user_id, category_id])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end

  def self.detailed_category_spending_over_time(category_id, user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array,
                                            [DETAILED_CATEGORY_PER_MONTH_SQL, user_id, category_id])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end

  def self.merchant_spending_over_time(merchant_name, user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array,
                                            [MERCHANT_PER_MONTH_SQL,
                                             user_id,
                                             '%' + merchant_name + '%',
                                             '%' + merchant_name + '%'])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end

  def self.label_spending_over_time(label_id, user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array,
                                            [LABEL_PER_MONTH_SQL,
                                             user_id,
                                             label_id])
    ActiveRecord::Base.connection.execute(sanitized_sql)
  end
end
