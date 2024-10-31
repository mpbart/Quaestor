# frozen_string_literal: true

class RulesController < ApplicationController
  before_action :authenticate_user!

  def index
    @transaction_rules = TransactionRule.all.to_a
  end

  def create
    filtered_params = params.require(:rule).permit(
      :account_id, :description, :amount, :updated_merchant, :updated_description,
      :updated_category_id, :updated_label_id
    )

    transaction_rule = TransactionRule.create!(
      field_replacement_mappings: {
        description:       filtered_params[:updated_description],
        merchant:          filtered_params[:updated_merchant],
        plaid_category_id: filtered_params[:updated_category_id],
        label_id:          filtered_params[:updated_label_id]
      }.compact_blank
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
end
