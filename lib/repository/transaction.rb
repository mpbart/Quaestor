module Repository
  class Transaction
    class BadParametersError < StandardError; end

    def self.add(transactions)
      transactions.each{ |t| Entity::Transaction.create(t) }
    end

    def self.update(transactions)
      transactions.each{ |t| Entity::Transaction.new(t.transaction_id).update(t) }
    end

    def self.remove(transactions)
      transactions.each{ |t| Entity::Transaction.new(t.transaction_id).remove }
    end

    def self.split!(new_transaction_details)
      begin
        parent_transaction_id = new_transaction_details.delete(:parent_transaction_id)
        return unless transaction = ::Transaction.find(parent_transaction_id)

        if new_transaction_details[:amount].nil?
          raise BadParametersError.new("Amount must be filled when splitting a transaction")
        end

        return false unless new_transaction_details[:amount].to_f > 0.0

        ActiveRecord::Base.transaction do
          new_transaction_record = ::Transaction.create!(original_transaction.attributes.except('id')
            .merge(new_transaction_details.reject{ |k,v| v.blank? })
            .merge({id: generate_transaction_id, split: true})
          )
          new_transaction_record.split = true
          new_transaction_record.save!

          original_transaction.amount -= BigDecimal(new_transaction_details[:amount].to_s)
          original_transaction.split = true
          original_transaction.save!

          if original_transaction.transaction_group.present?
            group = original_transaction.transaction_group
            group.transactions << new_transaction_record
          else
            group = ::TransactionGroup.create!
            group.transactions << original_transaction
            group.transactions << new_transaction_record
          end
        end

        true
      rescue => e
        Rails.logger.error("Error splitting transaction: #{e}")
        false
      end
    end
  end
end
