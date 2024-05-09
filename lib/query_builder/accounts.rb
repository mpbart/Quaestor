module QueryBuilder
  module Accounts
    def accounts_table
      @accounts_table ||= Arel::Table.new(:accounts)
    end

    def account_id(value)
      accounts_table[:id].eq(value)
    end
  end
end
