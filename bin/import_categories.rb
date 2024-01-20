# frozen_string_literal: true

require 'plaid'
require 'config_reader'

# Use this script to re-initialize the plaid_categories database table if it
# gets wiped

config = ConfigReader.for('plaid')
client = Plaid::Client.new(env: :sandbox, client_id: config['client_id'], secret: config['secret'])
client.categories.get['categories'].each do |cat|
  PlaidCategory.create!(hierarchy: cat.hierarchy, category_id: cat.category_id)
end
