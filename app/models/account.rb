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
end
