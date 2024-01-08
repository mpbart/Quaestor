FactoryBot.define do
  factory :user do
    email { 'test.email@email.com' }
    password { SecureRandom.uuid }
  end
end
