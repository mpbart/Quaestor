# frozen_string_literal: true

require 'csv'
require 'pry'

account_map = Account.all.to_h { |a| [a.name, a] }.merge(Account.all.to_h do |a|
  [a.official_name, a]
end)
account_map.delete(nil)

count = 0
ActiveRecord::Base.transaction do
  CSV.open('transactions.csv', headers: true).each do |row|
    acct = account_map[row['Account Name']]
    next unless acct

    trans = Transaction.find_by(date:        DateTime.strptime(row['Date'], '%m/%d/%Y').in_time_zone,
                                description: row['Description'])
    next unless trans && trans.account_id.nil?

    count += 1
    trans.account_id = acct.id
    trans.save!
  end
end
