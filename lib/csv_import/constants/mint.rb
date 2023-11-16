module CsvImport
  module Constants
    class Mint
      class TransactionType
        CREDIT = 'credit'.freeze
        DEBIT = 'debit'.freeze
      end

      def map_category(category, description)
        self.class.mappings.dig(category).call(description)
      end

      def self.mappings
        @mappings ||= begin
          conversions = {
            'Auto Insurance' => ['GENERAL_SERVICES', 'LOAN_PAYMENTS_CAR_PAYMENT'],
            'Auto Payment' => ['LOAN_PAYMENTS', 'LOAN_PAYMENTS_CAR_PAYMENT'],
            'Gas & Fuel' => ['TRANSPORTATION', 'TRANSPORTATION_GAS'],
            'Parking' => ['TRANSPORTATION', 'TRANSPORTATION_PARKING'],
            'Public Transportation' => ['TRANSPORTATION', 'TRANSPORTATION_PUBLIC_TRANSIT'],
            'Service & Parts' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_AUTOMOTIVE'],
            'Home Phone' => ['RENT_AND_UTILITIES', 'RENT_AND_UTILITIES_TELEPHONE'],
            'Internet' => ['RENT_AND_UTILITIES', 'RENT_AND_UTILITIES_INTERNET_AND_CABLE'],
            'Mobile Phone' => ['RENT_AND_UTILITIES', 'RENT_AND_UTILITIES_TELEPHONE'],
            'Television' => ['RENT_AND_UTILITIES', 'RENT_AND_UTILITIES_INTERNET_AND_CABLE'],
            'Utilities' => ['RENT_AND_UTILITIES', 'RENT_AND_UTILITIES_GAS_AND_ELECTRICITY'],
            'Advertising' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_OTHER_GENERAL_SERVICES'],
            'Legal' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_CONSULTING_AND_LEGAL'],
            'Office Supplies' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_OFFICE_SUPPLIES'],
            'Printing' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_POSTAGE_AND_SHIPPING'],
            'Shipping' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_POSTAGE_AND_SHIPPING'],
            'Books & Supplies' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS'],
            'Student Loan' => ['LOAN_PAYMENTS', 'LOAN_PAYMENTS_STUDENT_LOAN_PAYMENT'],
            'Tuition' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_EDUCATION'],
            'Amusement' => ['ENTERTAINMENT', 'ENTERTAINMENT_OTHER_ENTERTAINMENT'],
            'Arts' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE'],
            'Movies & DVDs' => ['ENTERTAINMENT', 'ENTERTAINMENT_TV_AND_MOVIES'],
            'Music' => ['ENTERTAINMENT', 'ENTERTAINMENT_MUSIC_AND_AUDIO'],
            'Newspapers & Magazines' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS'],
            'Relaxation' => ['ENTERTAINMENT', 'ENTERTAINMENT_OTHER_ENTERTAINMENT'],
            'Sports Tickets' => ['ENTERTAINMENT', 'ENTERTAINMENT_SPORTING_EVENTS_AMUSEMENT_PARKS_AND_MUSEUMS'],
            'ATM Fee' => ['BANK_FEES', 'BANK_FEES_ATM_FEES'],
            'Bank Fee' => ['BANK_FEES', 'BANK_FEES_OTHER_BANK_FEES'],
            'Finance Charge' => ['BANK_FEES', 'BANK_FEES_OTHER_BANK_FEES'],
            'Late Fee' => ['BANK_FEES', 'BANK_FEES_OTHER_BANK_FEES'],
            'Service Fee' => ['BANK_FEES', 'BANK_FEES_OTHER_BANK_FEES'],
            'Trade Commissions' => ['BANK_FEES', 'BANK_FEES_OTHER_BANK_FEES'],
            'Financial Advisor' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_ACCOUNTING_AND_FINANCIAL_PLANNING'],
            'Life Insurance    ' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_INSURANCE'],
            'Alcohol & Bars' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_RESTAURANT'],
            'Coffee Shops' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_COFFEE'],
            'Fast Food' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_FAST_FOOD'],
            'Groceries' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_GROCERIES'],
            'Restaurants' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_RESTAURANT'],
            'Lunch' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_LUNCH'],
            'Charity' => ['GOVERNMENT_AND_NON_PROFIT', 'GOVERNMENT_AND_NON_PROFIT_DONATIONS'],
            'Gift' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_GIFTS_AND_NOVELTIES'],
            'Gifts & Donations' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_GIFTS_AND_NOVELTIES'],
            'Engagement Ring' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_ENGAGEMENT_RING'],
            'Dentist' => ['MEDICAL', 'MEDICAL_DENTAL_CARE'],
            'Doctor' => ['MEDICAL', 'MEDICAL_PRIMARY_CARE'],
            'Eyecare' => ['MEDICAL', 'MEDICAL_EYE_CARE'],
            'Gym' => ['PERSONAL_CARE', 'PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS'],
            'Health Insurance' => ['GENERAL_SERVICES', 'PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS'],
            'Pharmacy' => ['MEDICAL', 'MEDICAL_PHARMACIES_AND_SUPPLEMENTS'],
            'Sports' => ['PERSONAL_CARE', 'PERSONAL_CARE_SPORTS'],
            'Furnishings' => ['HOME_IMPROVEMENT', 'HOME_IMPROVEMENT_FURNITURE'],
            'Home Improvement' => ['HOME_IMPROVEMENT', 'HOME_IMPROVEMENT_REPAIR_AND_MAINTENANCE'],
            'Home Insurance' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_INSURANCE'],
            'Home Services' => ['HOME_IMPROVEMENT', 'HOME_IMPROVEMENT_REPAIR_AND_MAINTENANCE'],
            'Home Supplies' => ['HOME_IMPROVEMENT', 'HOME_IMPROVEMENT_HARDWARE'],
            'Lawn & Garden' => ['HOME_IMPROVEMENT', 'HOME_IMPROVEMENT_HARDWARE'],
            'Mortgage & Rent' => ->(description) { classify_mortgage_and_rent_category(description) },
            'Down Payment' => ['LOAN_PAYMENTS', 'LOAN_PAYMENTS_DOWN_PAYMENT'],
            'Move in fee' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_MOVING'],
            'Moving Expenses' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_MOVING'],
            'Bonus' => ['INCOME', 'INCOME_BONUS'],
            'Interest Income' => ['INCOME', 'INCOME_INTEREST_EARNED'],
            'Paycheck' => ['INCOME', 'INCOME_WAGES'],
            'Reimbursement' => ['INCOME', 'INCOME_WAGES'],
            'Rental Income' => ['INCOME', 'INCOME_OTHER_INCOME'],
            'Returned Purchase' => ['INCOME', 'INCOME_OTHER_INCOME'],
            'Buy' => ['TRANSFER_OUT', 'TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS'],
            'Deposit' => ['TRANSFER_IN', 'TRANSFER_IN_DEPOSIT'],
            'Dividend & Cap Gains' => ['INCOME', 'INCOME_DIVIDENDS'],
            'Sell' => ['TRANSFER_IN', 'TRANSFER_IN_INVESTMENT_AND_RETIREMENT_FUNDS'],
            'Withdrawal' => ['TRANSFER_OUT', 'TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS'],
            'Loan Interest' => ['BANK_FEES', 'BANK_FEES_INTEREST_CHARGE'],
            'Loan Payment' => ['LOAN_PAYMENTS', 'LOAN_PAYMENTS_MORTGAGE_PAYMENT'],
            'Loan Principal' => ['LOAN_PAYMENTS', 'LOAN_PAYMENTS_MORTGAGE_PAYMENT'],
            'Loans' => ['EXCLUDED', 'EXCLUDED_EXCLUDED'],
            'Wedding' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_WEDDING'],
            'Hair' => ['PERSONAL_CARE', 'PERSONAL_CARE_HAIR_AND_BEAUTY'],
            'Laundry' => ['PERSONAL_CARE', 'PERSONAL_CARE_LAUNDRY_AND_DRY_CLEANING'],
            'Spa & Massage' => ['PERSONAL_CARE', 'PERSONAL_CARE_HAIR_AND_BEAUTY'],
            'Pet Food & Supplies' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_PET_SUPPLIES'],
            'Pet Grooming' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_PET_SUPPLIES'],
            'Veterinary' => ['MEDICAL', 'MEDICAL_VETERINARY_SERVICES'],
            'Books' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS'],
            'Clothing' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_CLOTHING_AND_ACCESSORIES'],
            'Electronics & Software' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_ELECTRONICS'],
            'Hobbies' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE'],
            'Sporting Goods' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_SPORTING_GOODS'],
            'Federal Tax' => ['GOVERNMENT_AND_NON_PROFIT', 'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT'],
            'Local Tax' => ['GOVERNMENT_AND_NON_PROFIT', 'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT'],
            'Property Tax' => ['GOVERNMENT_AND_NON_PROFIT', 'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT'],
            'Sales Tax' => ['GOVERNMENT_AND_NON_PROFIT', 'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT'],
            'State Tax' => ['GOVERNMENT_AND_NON_PROFIT', 'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT'],
            'Credit Card Payment' => ['LOAN_PAYMENTS', 'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT'],
            'Air Travel' => ['TRAVEL', 'TRAVEL_FLIGHTS'],
            'Hotel' => ['TRAVEL', 'TRAVEL_LODGING'],
            'Rental Car & Taxi' => ->(description) { classify_rental_car_and_taxi_category(description) },
            'Vacation' => ['TRAVEL', 'TRAVEL_VACATION'],
            'Cash & ATM' => ['TRANSFER_OUT', 'TRANSFER_OUT_WITHDRAWAL'],
            'Check' => ['TRANSFER_IN', 'TRANSFER_IN_DEPOSIT'],
            'Income' => ['INCOME', 'INCOME_OTHER_INCOME'],
            'Food & Dining' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_RESTAURANT'],
            'Food Delivery' => ['FOOD_AND_DRINK', 'FOOD_AND_DRINK_FOOD_DELIVERY'],
            'Bills & Utilities' => ['ENTERTAINMENT', 'ENTERTAINMENT_MUSIC_AND_AUDIO'],
            'Entertainment' => ['ENTERTAINMENT', 'ENTERTAINMENT_OTHER_ENTERTAINMENT'],
            'Taxes' => ['INCOME', 'INCOME_TAX_REFUND'],
            'Shopping' => ->(description) { classify_shopping_category(description) },
            'Fees & Charges' => ['BANK_FEES', 'BANK_FEES_OTHER_BANK_FEES'],
            'Transfer' => ->(description) { classify_transfer_category(description) },
            'Travel' => ->(description) { classify_travel_category(description) },
            'Business Services' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_OTHER_GENERAL_SERVICES'],
            'Health & Fitness' => ['PERSONAL_CARE', 'PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS'],
            'Auto & Transport' => ->(description) { classify_auto_category(description) },
            'Personal Care' => ['PERSONAL_CARE', 'PERSONAL_CARE_OTHER_PERSONAL_CARE'],
            'Investments' => ['EXCLUDED', 'EXCLUDED_EXCLUDED'],
            'Financial' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_ACCOUNTING_AND_FINANCIAL_PLANNING'],
            'Education' => ['GENERAL_SERVICES', 'GENERAL_SERVICES_OTHER_GENERAL_SERVICES'],
            'Rent application fee' => ['BANK_FEES', 'BANK_FEES_OTHER_BANK_FEES'],
            'Home' => ['EXCLUDED', 'EXCLUDED_EXCLUDED'],
            'Ride Share' => ['TRANSPORTATION', 'TRANSPORTATION_TAXIS_AND_RIDE_SHARES'],
            'Hide from Budgets & Trends' => ['EXCLUDED', 'EXCLUDED_EXCLUDED'],
            'Uncategorized' => ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE'],
            'Honeymoon' => ['TRAVEL', 'TRAVEL_VACATION'],
          }

          conversions.each do |_k, value|
            next if value.respond_to?(:call)

            conversions[_k] = ->(_) { value }
          end

          conversions
        end
      end

      private

      def self.classify_mortgage_and_rent_category(description)
        if description.match?(/citizens/i)
          ['LOAN_PAYMENTS', 'LOAN_PAYMENTS_MORTGAGE_PAYMENT']
        else
          ['RENT_AND_UTILITIES', 'RENT_AND_UTILITIES_RENT']
        end
      end

      def self.classify_rental_car_and_taxi_category(description)
        if description.match?(/hertz/i) || description.match?(/avis/i) || description.match?(/expedia/i) || description.match?(/alamo/i)
          ['TRAVEL', 'TRAVEL_RENTAL_CARS']
        else
          ['TRANSPORTATION', 'TRANSPORTATION_TAXIS_AND_RIDE_SHARES']
        end
      end

      def self.classify_shopping_category(description)
        if description.match?(/amazon/i)
          ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_ONLINE_MARKETPLACES']
        elsif description.match?(/dollar tree/i) || description.match?(/goodwill/i)
          ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_DISCOUNT_STORES']
        else
          ['GENERAL_MERCHANDISE', 'GENERAL_MERCHANDISE_SUPERSTORES']
        end
      end

      def self.classify_transfer_category(description)
        if description.match?(/venmo.*payment/i)
          ['TRANSFER_OUT', 'TRANSFER_OUT_ACCOUNT_TRANSFER']
        else
          ['TRANSFER_IN', 'TRANSFER_IN_ACCOUNT_TRANSFER']
        end
      end

      def self.classify_travel_category(description)
        if description.match?(/toll/i) || description.match?(/skyway/i) || description.match?(/itr.*concession/i)
          ['TRANSPORTATION', 'TRANSPORTATION_TOLLS']
        elsif description.match?(/amtrak/i)
          ['TRANSPORTATION', 'TRANSPORTATION_PUBLIC_TRANSIT']
        else
          ['TRAVEL', 'TRAVEL_OTHER_TRAVEL']
        end
      end

      def self.classify_auto_category(description)
        if description.match?(/toll/i) || description.match?(/bridge/i)
          ['TRANSPORTATION', 'TRANSPORTATION_TOLLS']
        elsif description.match?(/sec.*of.*state/i)
          ['GOVERNMENT_AND_NON_PROFIT', 'GOVERNMENT_AND_NON_PROFIT_GOVERNMENT_DEPARTMENTS_AND_AGENCIES']
        else
          ['GENERAL_SERVICES', 'GENERAL_SERVICES_AUTOMOTIVE']
        end
      end
    end
  end
end
