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

  MONTH_SQL = "DATE_TRUNC('MONTH', transactions.date)"

  def grouped_transactions
    return [] unless transaction_group

    transaction_group.transactions.where.not(id: id)
  end

  def self.search_by_label_name(user, label_name, page_num)
    joins(:labels).where(
      labels: { name: label_name }
    ).where(user_id: user.id)
                  .by_date
                  .paginate(page: page_num, per_page: 50)
                  .includes(:account, :plaid_category)
  end

  # Removes transactions matching any of the given exclusions. Supported keys:
  # :account_ids, :label_ids, :categories (detailed categories), :merchants
  # (substring match against merchant name or description).
  def self.apply_exclusions(exclusions = {})
    exclusions ||= {}
    relation = all

    account_ids = Array(exclusions[:account_ids]).map(&:to_i)
    relation = relation.where.not(account_id: account_ids) if account_ids.any?

    label_ids = Array(exclusions[:label_ids]).map(&:to_i)
    if label_ids.any?
      relation = relation.where(
        'transactions.id NOT IN (SELECT transaction_id FROM labels_transactions WHERE label_id IN (?))',
        label_ids
      )
    end

    categories = Array(exclusions[:categories])
    if categories.any?
      relation = relation.where(
        'transactions.plaid_category_id IS NULL OR transactions.plaid_category_id NOT IN ' \
        '(SELECT id FROM plaid_categories WHERE detailed_category IN (?))',
        categories
      )
    end

    Array(exclusions[:merchants]).each do |merchant|
      pattern = "%#{sanitize_sql_like(merchant)}%"
      relation = relation.where(
        "NOT (COALESCE(transactions.merchant_name, '') ILIKE :p OR " \
        "COALESCE(transactions.description, '') ILIKE :p)",
        p: pattern
      )
    end

    relation
  end

  # Transactions belonging to the user's accounts, with exclusions applied.
  def self.for_analytics(user_id, exclusions = {})
    joins(:account).where(accounts: { user_id: user_id }).apply_exclusions(exclusions)
  end

  def self.monthly_totals(relation)
    relation.group(Arel.sql(MONTH_SQL))
            .order(Arel.sql(MONTH_SQL))
            .pluck(Arel.sql('SUM(transactions.amount)'), Arel.sql(MONTH_SQL))
            .map { |total, month| { 'total' => total, 'month' => month } }
  end

  def self.total_spending_over_time(user_id, exclusions = {})
    monthly_totals(
      for_analytics(user_id, exclusions)
        .joins(:plaid_category)
        .where.not(plaid_categories: { primary_category: 'INCOME' })
        .where.not(plaid_categories: { detailed_category: ::PlaidCategory::EXCLUDED_CATEGORIES })
    )
  end

  def self.total_income_over_time(user_id, exclusions = {})
    monthly_totals(
      for_analytics(user_id, exclusions)
        .joins(:plaid_category)
        .where(plaid_categories: { primary_category: 'INCOME' })
        .where.not(plaid_categories: { detailed_category: ::PlaidCategory::EXCLUDED_CATEGORIES })
    )
  end

  def self.category_totals(user_id)
    sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [CUMULATIVE_TOTALS_SQL, user_id])
    connection_pool.with_connection { |connection| connection.execute(sanitized_sql) }
  end

  def self.primary_category_spending_over_time(category_id, user_id, exclusions = {})
    monthly_totals(
      for_analytics(user_id, exclusions)
        .joins(:plaid_category)
        .where(plaid_categories: { primary_category: category_id })
    )
  end

  def self.detailed_category_spending_over_time(category_id, user_id, exclusions = {})
    monthly_totals(
      for_analytics(user_id, exclusions)
        .joins(:plaid_category)
        .where(plaid_categories: { detailed_category: category_id })
    )
  end

  def self.merchant_spending_over_time(merchant_name, user_id, exclusions = {})
    pattern = "%#{merchant_name}%"
    monthly_totals(
      for_analytics(user_id, exclusions)
        .where('transactions.merchant_name ILIKE :p OR transactions.description ILIKE :p', p: pattern)
    )
  end

  def self.label_spending_over_time(label_id, user_id, exclusions = {})
    monthly_totals(
      for_analytics(user_id, exclusions)
        .joins(:labels)
        .where(labels: { id: label_id })
    )
  end

  def self.spending_by_category_over_time(user_id, exclusions = {})
    relation = for_analytics(user_id, exclusions)
               .joins(:plaid_category)
               .where.not(plaid_categories: { primary_category: 'INCOME' })
               .where.not(plaid_categories: { detailed_category: ::PlaidCategory::EXCLUDED_CATEGORIES })

    relation.group(Arel.sql(MONTH_SQL), 'plaid_categories.primary_category')
            .order(Arel.sql(MONTH_SQL))
            .pluck(Arel.sql('SUM(transactions.amount)'), Arel.sql(MONTH_SQL),
                   'plaid_categories.primary_category')
            .map { |total, month, category| { 'total' => total, 'month' => month, 'category' => category } }
  end
end
