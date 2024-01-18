FactoryBot.define do
  factory :user do
    email { 'test.email' + SecureRandom.uuid + '@email.com' }
    password { SecureRandom.uuid }
  end
end
