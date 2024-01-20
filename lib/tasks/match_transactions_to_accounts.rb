require 'csv'
require 'pry'

account_map = Account.all.map { |a| [a.name, a] }.to_h.merge(Account.all.map do |a|
  [a.official_name, a]
end.to_h)
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
