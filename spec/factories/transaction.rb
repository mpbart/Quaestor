FactoryBot.define do
  factory :transaction do
    user
    account
    plaid_category

    id { SecureRandom.uuid }
    description { "test transaction" }
    amount { 10.0 }
    date { Date.current }
    pending { false }
  end
end
