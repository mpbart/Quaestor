# frozen_string_literal: true

class RulesController < ApplicationController
  before_action :authenticate_user!

  def index
    @transaction_rules = TransactionRule.all.to_a
  end

  def create
    filtered_params = params.require(:rule).permit(
      :account_id, :description, :amount, :updated_merchant, :updated_description,
      :updated_category_id, :updated_label_id,
      :split_category_id, :split_amount, :split_description, :split_merchant_name,
      split_labels: [] # For array of label IDs
    )

    transaction_rule = TransactionRule.create!(
      field_replacement_mappings: {
        description:       filtered_params[:updated_description],
        merchant:          filtered_params[:updated_merchant],
        plaid_category_id: filtered_params[:updated_category_id],
        label_id:          filtered_params[:updated_label_id]
      }.compact_blank,
      split_category_id:          filtered_params[:split_category_id],
      split_amount:               filtered_params[:split_amount],
      split_description:          filtered_params[:split_description],
      split_merchant_name:        filtered_params[:split_merchant_name],
      split_labels:               filtered_params[:split_labels]
    )

    [:account_id, :description, :amount].each do |key|
      value = filtered_params[key]
      next unless value.present?

      qualifier = map_field_to_qualifier(key)
      RuleCriteria.create!(
        field_name:       key,
        field_qualifier:  qualifier,
        value_comparator: value,
        transaction_rule: transaction_rule
      )
    end

    redirect_to rules_url
  end

  def map_field_to_qualifier(field)
    case field.to_s
    when 'account_id', 'amount'
      '=='
    when 'description'
      'contains'
    end
  end

  def edit
    @transaction_rule = TransactionRule.find(params[:id])
    @rule_criteria = @transaction_rule.rule_criteria.index_by(&:field_name)
    @accounts = Account.all
    @plaid_categories = PlaidCategory.all
    @labels = Label.all
  end

  def update
    transaction_rule = TransactionRule.find(params[:id])
    filtered_params = params.require(:rule).permit(
      :account_id, :description, :amount, :updated_merchant, :updated_description,
      :updated_category_id, :updated_label_id,
      :split_category_id, :split_amount, :split_description, :split_merchant_name,
      split_labels: [] # For array of label IDs
    )

    transaction_rule.update!(
      field_replacement_mappings: {
        description:       filtered_params[:updated_description],
        merchant:          filtered_params[:updated_merchant],
        plaid_category_id: filtered_params[:updated_category_id],
        label_id:          filtered_params[:updated_label_id]
      }.compact_blank,
      split_category_id:          filtered_params[:split_category_id],
      split_amount:               filtered_params[:split_amount],
      split_description:          filtered_params[:split_description],
      split_merchant_name:        filtered_params[:split_merchant_name],
      split_labels:               filtered_params[:split_labels]
    )

    transaction_rule.rule_criteria.destroy_all

    [:account_id, :description, :amount].each do |key|
      value = filtered_params[key]
      next unless value.present?

      qualifier = map_field_to_qualifier(key)
      RuleCriteria.create!(
        field_name:       key,
        field_qualifier:  qualifier,
        value_comparator: value,
        transaction_rule: transaction_rule
      )
    end

    redirect_to rules_url
  end
end
