FactoryBot.define do
  factory :transaction do
    user
    account
    plaid_category

    id { SecureRandom.uuid }
    description { 'test transaction' }
    amount { 10.0 }
    date { Date.current }
    category_confidence { 'HIGH' }
    merchant_name       { 'merchant' }
    payment_channel     { 'in store' }
    payment_metadata    { {} }
    location_metadata   { {} }
    pending { false }
    account_owner { account.mask }
  end
end
