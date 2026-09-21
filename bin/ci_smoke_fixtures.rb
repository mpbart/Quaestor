# frozen_string_literal: true

# Creates the minimum dataset the production smoke test needs, then prints the
# identifiers the driver has to reuse. Run with:
#
#   bundle exec rails runner bin/ci_smoke_fixtures.rb
#
# It is written to be re-runnable, and is only ever pointed at the throwaway
# database created by bin/ci_smoke_test.sh.

email = ENV.fetch('SMOKE_USER_EMAIL', 'smoke@example.com')
password = ENV.fetch('SMOKE_USER_PASSWORD', 'ci-smoke-password')

category = PlaidCategory.find_or_initialize_by(detailed_category: 'FOOD_AND_DRINK_GROCERIES')
category.primary_category = 'FOOD_AND_DRINK'
category.save!

user = User.find_or_initialize_by(email: email)
user.password = password
user.password_confirmation = password
user.save!

account = Account.find_or_initialize_by(plaid_identifier: 'ci-smoke-account', user_id: user.id)
account.assign_attributes(
  name:             'CI Smoke Account',
  official_name:    'CI Smoke Account',
  account_type:     'depository',
  account_sub_type: 'checking',
  mask:             '0000',
  institution_name: 'CI Smoke',
  institution_id:   1,
  inactive:         false
)
account.save!

# A balance in the current month keeps BalancesWorker a no-op, so the smoke test
# can use it as a harmless job to prove Sidekiq is consuming work.
account.balances.create!(amount: 1000.0, available: 1000.0, created_at: Time.current) if account.balances.none?

transaction = Transaction.find_or_initialize_by(id: 'ci-smoke-transaction')
transaction.assign_attributes(
  user:                user,
  account:             account,
  plaid_category:      category,
  description:         'CI smoke transaction',
  amount:              42.0,
  date:                Date.current,
  category_confidence: 'HIGH',
  merchant_name:       'CI Smoke Merchant',
  payment_channel:     'online',
  payment_metadata:    {},
  location_metadata:   {},
  pending:             false,
  account_owner:       account.mask
)
transaction.save!

puts "SMOKE_USER_EMAIL=#{user.email}"
puts "SMOKE_USER_PASSWORD=#{password}"
puts "SMOKE_ACCOUNT_ID=#{account.id}"
puts "SMOKE_TRANSACTION_ID=#{transaction.id}"
