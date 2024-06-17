require 'factory_bot'
FactoryBot.find_definitions unless FactoryBot.factories.registered?(:transaction)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :depository),
  plaid_category: PlaidCategory.find_by(detailed_category: "INCOME_WAGES"),
  user: User.last,
  description: "Paycheck from Acme Inc.",
  amount: -2000.0,
  date: 1.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :depository),
  plaid_category: PlaidCategory.find_by(detailed_category: "INCOME_WAGES"),
  user: User.last,
  description: "Paycheck from Acme Inc.",
  amount: -2000.0,
  date: 15.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :investment),
  plaid_category: PlaidCategory.find_by(detailed_category: "INCOME_DIVIDENDS"),
  user: User.last,
  description: "Quarter 1 dividend",
  amount: -1300.0,
  date: 10.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :depository),
  plaid_category: PlaidCategory.find_by(detailed_category: "LOAN_PAYMENTS_MORTGAGE_PAYMENT"),
  user: User.last,
  description: "Monthly Mortgage Payment",
  amount: 1000.0,
  date: 9.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :depository),
  plaid_category: PlaidCategory.find_by(detailed_category: "LOAN_PAYMENTS_CAR_PAYMENT"),
  user: User.last,
  description: "Monthly Car Loan Payment",
  amount: 500.0,
  date: 2.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :depository),
  plaid_category: PlaidCategory.find_by(detailed_category: "GENERAL_SERVICES_INSURANCE"),
  user: User.last,
  description: "Monthly Insurance Premium",
  amount: 500.0,
  date: 5.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :depository),
  plaid_category: PlaidCategory.find_by(detailed_category: "RENT_AND_UTILITIES_INTERNET_AND_CABLE"),
  user: User.last,
  description: "ISP Bill",
  amount: 100.0,
  date: 3.days.ago,
)


# Non-recurring transactions
FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :credit),
  plaid_category: PlaidCategory.find_by(detailed_category: "FOOD_AND_DRINK_COFFEE"),
  user: User.last,
  description: "Coffee Shop Cafe",
  amount: 10.0,
  date: 4.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :credit),
  plaid_category: PlaidCategory.find_by(detailed_category: "FOOD_AND_DRINK_FAST_FOOD"),
  user: User.last,
  description: "Taco Hut King",
  amount: 21.22,
  date: 6.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :credit),
  plaid_category: PlaidCategory.find_by(detailed_category: "FOOD_AND_DRINK_RESTAURANT"),
  user: User.last,
  description: "Ristorante Italiano",
  amount: 55.50,
  date: 1.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :credit),
  plaid_category: PlaidCategory.find_by(detailed_category: "GENERAL_MERCHANDISE_CLOTHING_AND_ACCESSORIES"),
  user: User.last,
  description: "Fashionable Boutique",
  amount: 57.61,
  date: 8.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :credit),
  plaid_category: PlaidCategory.find_by(detailed_category: "GENERAL_MERCHANDISE_ONLINE_MARKETPLACES"),
  user: User.last,
  description: "Rainforest.com Online Order",
  amount: 33.94,
  date: 13.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :credit),
  plaid_category: PlaidCategory.find_by(detailed_category: "ENTERTAINMENT_SPORTING_EVENTS_AMUSEMENT_PARKS_AND_MUSEUMS"),
  user: User.last,
  description: "Baseball Game",
  amount: 111.07,
  date: 15.days.ago,
)

FactoryBot.create(
  :transaction,
  account: Account.find_by(account_type: :credit),
  plaid_category: PlaidCategory.find_by(detailed_category: "TRANSPORTATION_GAS"),
  user: User.last,
  description: "Gas Station",
  amount: 44.99,
  date: 11.days.ago,
)
