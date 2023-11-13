require 'faraday'
require 'csv'

response = Faraday.new(url: 'https://plaid.com/documents/transactions-personal-finance-category-taxonomy.csv').get
puts "Failure response retrieving plaid transaction categories - status: #{response.status}" unless response.success?

records_inserted = 0
puts "Seeding categories from plaid"
CSV.parse(response.body, headers: true).each do |row|
  PlaidCategory.find_or_create_by(primary_category: row['PRIMARY'], detailed_category: row['DETAILED']) do |record|
    record.description = row['DESCRIPTION']
    records_inserted += 1
  end
end

puts "Seeding custom categories from custom_categories.csv"
CSV.open(Rails.root.join('db', 'seeds', 'custom_categories.csv'), headers: true).each do |row|
  PlaidCategory.find_or_create_by(primary_category: row['PRIMARY'], detailed_category: row['DETAILED']) do |record|
    record.description = row['DESCRIPTION']
    records_inserted += 1
  end
end

puts "Successfully seeded #{records_inserted} categories"
