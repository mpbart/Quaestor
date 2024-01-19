FactoryBot.define do
  factory :plaid_credential do
    user
    plaid_item_id { SecureRandom.uuid }
    institution_name { 'institution' }
    institution_id { 'id' }
    cursor { 'cursor' }
    access_token { 'token' }
  end
end
