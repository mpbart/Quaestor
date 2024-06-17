require 'factory_bot'
FactoryBot.find_definitions unless FactoryBot.factories.registered?(:account)

acct = FactoryBot.create(:account,
                  name: "Mortgage",
                  official_name: "Home Mortgage",
                  account_type: 'loan',
                  account_sub_type: 'mortgage',
                  institution_name: "Bank",
                  user: User.last)
Balance.create!(account: acct, amount: 100_000.55)

acct = FactoryBot.create(:account,
                  name: "Credit Card 1",
                  official_name: "Credit Card A",
                  account_type: 'credit',
                  account_sub_type: 'credit_card',
                  institution_name: "Online Bank",
                  user: User.last)
Balance.create!(account: acct, amount: 120.21)

acct = FactoryBot.create(:account,
                  name: "Credit Card 2",
                  official_name: "Credit Card B",
                  account_type: 'credit',
                  account_sub_type: 'credit_card',
                  institution_name: "Online Bank",
                  user: User.last)
Balance.create!(account: acct, amount: 10.98)

acct = FactoryBot.create(:account,
                  name: "Checking Account",
                  official_name: "Checking Account",
                  account_type: 'depository',
                  account_sub_type: 'checking',
                  institution_name: "Physical Bank",
                  user: User.last)
Balance.create!(account: acct, amount: 5320.75)

acct = FactoryBot.create(:account,
                  name: "Investment Account",
                  official_name: "Brokerage Account",
                  account_type: 'investment',
                  account_sub_type: 'brokerage',
                  institution_name: "Investment Bank",
                  user: User.last)
Balance.create!(account: acct, amount: 140_224.28)
