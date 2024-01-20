FactoryBot.define do
  factory :account do
    user

    name { 'test account' }
    plaid_identifier { SecureRandom.uuid }
    official_name { 'Test Checking Account' }
    account_type { 'Checking' }
    account_sub_type { 'Checking' }
    mask { '***1234' }
    institution_name { 'Test' }
    institution_id { 1 }
  end
end
