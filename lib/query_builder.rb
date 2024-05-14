# frozen_string_literal: true

require 'query_builder/transactions'
require 'query_builder/accounts'
require 'query_builder/plaid_categories'
require 'query_builder/labels'

module QueryBuilder
  extend QueryBuilder::Transactions
  extend QueryBuilder::Accounts
  extend QueryBuilder::PlaidCategories
  extend QueryBuilder::Labels

  FILTER_PARAMS = %w[q account_id plaid_category_id label_id start_date end_date].freeze

  def self.filter(current_user, params)
    if filters_applied?(params)
      where_clause = build_where(params)
      current_user.transactions
                  .joins(:account)
                  .joins(:plaid_category)
                  .left_joins(:labels)
                  .by_date
                  .paginate(page: params['page']&.to_i || 1, per_page: 50)
                  .includes(:account, :plaid_category, :labels)
                  .where(where_clause)
    else
      current_user.paginated_transactions(page_num: params[:page]&.to_i || 1)
                  .includes(:account, :plaid_category)
    end
  end

  def self.build_where(params)
    params.compact_blank.slice(*FILTER_PARAMS).to_h.map do |key, value|
      send(key, value)
    end.compact.reduce(:and)
  end

  def self.filters_applied?(params)
    (params.keys & FILTER_PARAMS).any?
  end
end
