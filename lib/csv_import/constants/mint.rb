# frozen_string_literal: true

module CsvImport
  module Constants
    class Mint
      class TransactionType
        CREDIT = 'credit'
        DEBIT = 'debit'
      end

      def map_category(category, description)
        self.class.mappings[category].call(description)
      rescue StandardError
        puts "Error mapping category: #{category} with description: #{description}"
      end

      def self.mappings
        @mappings ||= begin
          # rubocop:disable Layout/LineLength
          conversions = {
            'Auto Insurance'             => %w[GENERAL_SERVICES LOAN_PAYMENTS_CAR_PAYMENT],
            'Auto Payment'               => %w[LOAN_PAYMENTS LOAN_PAYMENTS_CAR_PAYMENT],
            'Gas & Fuel'                 => %w[TRANSPORTATION TRANSPORTATION_GAS],
            'Parking'                    => %w[TRANSPORTATION TRANSPORTATION_PARKING],
            'Public Transportation'      => %w[TRANSPORTATION TRANSPORTATION_PUBLIC_TRANSIT],
            'Service & Parts'            => %w[GENERAL_SERVICES GENERAL_SERVICES_AUTOMOTIVE],
            'Home Phone'                 => %w[RENT_AND_UTILITIES RENT_AND_UTILITIES_TELEPHONE],
            'Internet'                   => %w[RENT_AND_UTILITIES
                                               RENT_AND_UTILITIES_INTERNET_AND_CABLE],
            'Mobile Phone'               => %w[RENT_AND_UTILITIES RENT_AND_UTILITIES_TELEPHONE],
            'Television'                 => %w[RENT_AND_UTILITIES
                                               RENT_AND_UTILITIES_INTERNET_AND_CABLE],
            'Utilities'                  => %w[RENT_AND_UTILITIES
                                               RENT_AND_UTILITIES_GAS_AND_ELECTRICITY],
            'Advertising'                => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_OTHER_GENERAL_SERVICES],
            'Legal'                      => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_CONSULTING_AND_LEGAL],
            'Office Supplies'            => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_OFFICE_SUPPLIES],
            'Printing'                   => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_POSTAGE_AND_SHIPPING],
            'Shipping'                   => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_POSTAGE_AND_SHIPPING],
            'Books & Supplies'           => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS],
            'Student Loan'               => %w[LOAN_PAYMENTS LOAN_PAYMENTS_STUDENT_LOAN_PAYMENT],
            'Tuition'                    => %w[GENERAL_SERVICES GENERAL_SERVICES_EDUCATION],
            'Amusement'                  => %w[ENTERTAINMENT ENTERTAINMENT_OTHER_ENTERTAINMENT],
            'Arts'                       => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE],
            'Movies & DVDs'              => %w[ENTERTAINMENT ENTERTAINMENT_TV_AND_MOVIES],
            'Music'                      => %w[ENTERTAINMENT ENTERTAINMENT_MUSIC_AND_AUDIO],
            'Newspapers & Magazines'     => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS],
            'Relaxation'                 => %w[ENTERTAINMENT ENTERTAINMENT_OTHER_ENTERTAINMENT],
            'Sports Tickets'             => %w[ENTERTAINMENT
                                               ENTERTAINMENT_SPORTING_EVENTS_AMUSEMENT_PARKS_AND_MUSEUMS],
            'ATM Fee'                    => %w[BANK_FEES BANK_FEES_ATM_FEES],
            'Bank Fee'                   => %w[BANK_FEES BANK_FEES_OTHER_BANK_FEES],
            'Finance Charge'             => %w[BANK_FEES BANK_FEES_OTHER_BANK_FEES],
            'Late Fee'                   => %w[BANK_FEES BANK_FEES_OTHER_BANK_FEES],
            'Service Fee'                => %w[BANK_FEES BANK_FEES_OTHER_BANK_FEES],
            'Trade Commissions'          => %w[BANK_FEES BANK_FEES_OTHER_BANK_FEES],
            'Financial Advisor'          => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_ACCOUNTING_AND_FINANCIAL_PLANNING],
            'Life Insurance    '         => %w[GENERAL_SERVICES GENERAL_SERVICES_INSURANCE],
            'Alcohol & Bars'             => %w[FOOD_AND_DRINK FOOD_AND_DRINK_RESTAURANT],
            'Coffee Shops'               => %w[FOOD_AND_DRINK FOOD_AND_DRINK_COFFEE],
            'Fast Food'                  => %w[FOOD_AND_DRINK FOOD_AND_DRINK_FAST_FOOD],
            'Groceries'                  => %w[FOOD_AND_DRINK FOOD_AND_DRINK_GROCERIES],
            'Restaurants'                => %w[FOOD_AND_DRINK FOOD_AND_DRINK_RESTAURANT],
            'Lunch'                      => %w[FOOD_AND_DRINK FOOD_AND_DRINK_LUNCH],
            'Charity'                    => %w[GOVERNMENT_AND_NON_PROFIT
                                               GOVERNMENT_AND_NON_PROFIT_DONATIONS],
            'Gift'                       => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_GIFTS_AND_NOVELTIES],
            'Gifts & Donations'          => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_GIFTS_AND_NOVELTIES],
            'Engagement Ring'            => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_ENGAGEMENT_RING],
            'Dentist'                    => %w[MEDICAL MEDICAL_DENTAL_CARE],
            'Doctor'                     => %w[MEDICAL MEDICAL_PRIMARY_CARE],
            'Eyecare'                    => %w[MEDICAL MEDICAL_EYE_CARE],
            'Gym'                        => %w[PERSONAL_CARE
                                               PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS],
            'Health Insurance'           => %w[GENERAL_SERVICES
                                               PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS],
            'Pharmacy'                   => %w[MEDICAL MEDICAL_PHARMACIES_AND_SUPPLEMENTS],
            'Sports'                     => %w[PERSONAL_CARE PERSONAL_CARE_SPORTS],
            'Furnishings'                => %w[HOME_IMPROVEMENT HOME_IMPROVEMENT_FURNITURE],
            'Home Improvement'           => %w[HOME_IMPROVEMENT
                                               HOME_IMPROVEMENT_REPAIR_AND_MAINTENANCE],
            'Home Insurance'             => %w[GENERAL_SERVICES GENERAL_SERVICES_INSURANCE],
            'Home Services'              => %w[HOME_IMPROVEMENT
                                               HOME_IMPROVEMENT_REPAIR_AND_MAINTENANCE],
            'Home Supplies'              => %w[HOME_IMPROVEMENT HOME_IMPROVEMENT_HARDWARE],
            'Lawn & Garden'              => %w[HOME_IMPROVEMENT HOME_IMPROVEMENT_HARDWARE],
            'Mortgage & Rent'            => lambda { |description|
                                              classify_mortgage_and_rent_category(description)
                                            },
            'Down Payment'               => %w[LOAN_PAYMENTS LOAN_PAYMENTS_DOWN_PAYMENT],
            'Move in fee'                => %w[GENERAL_SERVICES GENERAL_SERVICES_MOVING],
            'Moving Expenses'            => %w[GENERAL_SERVICES GENERAL_SERVICES_MOVING],
            'Bonus'                      => %w[INCOME INCOME_BONUS],
            'Interest Income'            => %w[INCOME INCOME_INTEREST_EARNED],
            'Paycheck'                   => %w[INCOME INCOME_WAGES],
            'Reimbursement'              => %w[INCOME INCOME_WAGES],
            'Rental Income'              => %w[INCOME INCOME_OTHER_INCOME],
            'Returned Purchase'          => %w[INCOME INCOME_OTHER_INCOME],
            'Buy'                        => %w[TRANSFER_OUT
                                               TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS],
            'Deposit'                    => %w[TRANSFER_IN TRANSFER_IN_DEPOSIT],
            'Dividend & Cap Gains'       => %w[INCOME INCOME_DIVIDENDS],
            'Sell'                       => %w[TRANSFER_IN
                                               TRANSFER_IN_INVESTMENT_AND_RETIREMENT_FUNDS],
            'Withdrawal'                 => %w[TRANSFER_OUT
                                               TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS],
            'Loan Interest'              => %w[BANK_FEES BANK_FEES_INTEREST_CHARGE],
            'Loan Payment'               => %w[LOAN_PAYMENTS LOAN_PAYMENTS_MORTGAGE_PAYMENT],
            'Loan Principal'             => %w[LOAN_PAYMENTS LOAN_PAYMENTS_MORTGAGE_PAYMENT],
            'Loans'                      => %w[EXCLUDED EXCLUDED_EXCLUDED],
            'Wedding'                    => %w[GENERAL_SERVICES GENERAL_SERVICES_WEDDING],
            'Hair'                       => %w[PERSONAL_CARE PERSONAL_CARE_HAIR_AND_BEAUTY],
            'Laundry'                    => %w[PERSONAL_CARE
                                               PERSONAL_CARE_LAUNDRY_AND_DRY_CLEANING],
            'Spa & Massage'              => %w[PERSONAL_CARE PERSONAL_CARE_HAIR_AND_BEAUTY],
            'Pet Food & Supplies'        => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_PET_SUPPLIES],
            'Pet Grooming'               => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_PET_SUPPLIES],
            'Veterinary'                 => %w[MEDICAL MEDICAL_VETERINARY_SERVICES],
            'Books'                      => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_BOOKSTORES_AND_NEWSSTANDS],
            'Clothing'                   => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_CLOTHING_AND_ACCESSORIES],
            'Electronics & Software'     => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_ELECTRONICS],
            'Hobbies'                    => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE],
            'Sporting Goods'             => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_SPORTING_GOODS],
            'Federal Tax'                => %w[GOVERNMENT_AND_NON_PROFIT
                                               GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT],
            'Local Tax'                  => %w[GOVERNMENT_AND_NON_PROFIT
                                               GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT],
            'Property Tax'               => %w[GOVERNMENT_AND_NON_PROFIT
                                               GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT],
            'Sales Tax'                  => %w[GOVERNMENT_AND_NON_PROFIT
                                               GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT],
            'State Tax'                  => %w[GOVERNMENT_AND_NON_PROFIT
                                               GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT],
            'Credit Card Payment'        => %w[LOAN_PAYMENTS LOAN_PAYMENTS_CREDIT_CARD_PAYMENT],
            'Air Travel'                 => %w[TRAVEL TRAVEL_FLIGHTS],
            'Hotel'                      => %w[TRAVEL TRAVEL_LODGING],
            'Rental Car & Taxi'          => lambda { |description|
                                              classify_rental_car_and_taxi_category(description)
                                            },
            'Vacation'                   => %w[TRAVEL TRAVEL_VACATION],
            'Cash & ATM'                 => %w[TRANSFER_OUT TRANSFER_OUT_WITHDRAWAL],
            'Check'                      => %w[TRANSFER_IN TRANSFER_IN_DEPOSIT],
            'Income'                     => %w[INCOME INCOME_OTHER_INCOME],
            'Food & Dining'              => %w[FOOD_AND_DRINK FOOD_AND_DRINK_RESTAURANT],
            'Food Delivery'              => %w[FOOD_AND_DRINK FOOD_AND_DRINK_FOOD_DELIVERY],
            'Bills & Utilities'          => %w[ENTERTAINMENT ENTERTAINMENT_MUSIC_AND_AUDIO],
            'Entertainment'              => %w[ENTERTAINMENT ENTERTAINMENT_OTHER_ENTERTAINMENT],
            'Taxes'                      => %w[INCOME INCOME_TAX_REFUND],
            'Shopping'                   => lambda { |description|
                                              classify_shopping_category(description)
                                            },
            'Fees & Charges'             => %w[BANK_FEES BANK_FEES_OTHER_BANK_FEES],
            'Transfer'                   => lambda { |description|
                                              classify_transfer_category(description)
                                            },
            'Transfer for Cash Spending' => %w[TRANSFER_OUT TRANSFER_OUT_WITHDRAWAL],
            'Travel'                     => lambda { |description|
                                              classify_travel_category(description)
                                            },
            'Business Services'          => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_OTHER_GENERAL_SERVICES],
            'Health & Fitness'           => %w[PERSONAL_CARE
                                               PERSONAL_CARE_GYMS_AND_FITNESS_CENTERS],
            'Auto & Transport'           => ->(description) { classify_auto_category(description) },
            'Personal Care'              => %w[PERSONAL_CARE PERSONAL_CARE_OTHER_PERSONAL_CARE],
            'Investments'                => %w[EXCLUDED EXCLUDED_EXCLUDED],
            'Financial'                  => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_ACCOUNTING_AND_FINANCIAL_PLANNING],
            'Education'                  => %w[GENERAL_SERVICES
                                               GENERAL_SERVICES_OTHER_GENERAL_SERVICES],
            'Rent application fee'       => %w[BANK_FEES BANK_FEES_OTHER_BANK_FEES],
            'Home'                       => %w[EXCLUDED EXCLUDED_EXCLUDED],
            'Ride Share'                 => %w[TRANSPORTATION
                                               TRANSPORTATION_TAXIS_AND_RIDE_SHARES],
            'Hide from Budgets & Trends' => %w[EXCLUDED EXCLUDED_EXCLUDED],
            'Uncategorized'              => %w[GENERAL_MERCHANDISE
                                               GENERAL_MERCHANDISE_OTHER_GENERAL_MERCHANDISE],
            'Honeymoon'                  => %w[TRAVEL TRAVEL_VACATION]
          }
          # rubocop:enable Layout/LineLength

          conversions.each do |_k, value|
            next if value.respond_to?(:call)

            conversions[_k] = ->(_) { value }
          end

          conversions
        end
      end

      def self.classify_mortgage_and_rent_category(description)
        if description.match?(/citizens/i)
          %w[LOAN_PAYMENTS LOAN_PAYMENTS_MORTGAGE_PAYMENT]
        else
          %w[RENT_AND_UTILITIES RENT_AND_UTILITIES_RENT]
        end
      end

      def self.classify_rental_car_and_taxi_category(description)
        if description.match?(/hertz/i) ||
           description.match?(/avis/i) ||
           description.match?(/expedia/i) ||
           description.match?(/alamo/i)
          %w[TRAVEL TRAVEL_RENTAL_CARS]
        else
          %w[TRANSPORTATION TRANSPORTATION_TAXIS_AND_RIDE_SHARES]
        end
      end

      def self.classify_shopping_category(description)
        if description.match?(/amazon/i)
          %w[GENERAL_MERCHANDISE GENERAL_MERCHANDISE_ONLINE_MARKETPLACES]
        elsif description.match?(/dollar tree/i) || description.match?(/goodwill/i)
          %w[GENERAL_MERCHANDISE GENERAL_MERCHANDISE_DISCOUNT_STORES]
        else
          %w[GENERAL_MERCHANDISE GENERAL_MERCHANDISE_SUPERSTORES]
        end
      end

      def self.classify_transfer_category(description)
        if description.match?(/venmo.*payment/i)
          %w[TRANSFER_OUT TRANSFER_OUT_ACCOUNT_TRANSFER]
        else
          %w[TRANSFER_IN TRANSFER_IN_ACCOUNT_TRANSFER]
        end
      end

      def self.classify_travel_category(description)
        if description.match?(/toll/i) ||
           description.match?(/skyway/i) ||
           description.match?(/itr.*concession/i)
          %w[TRANSPORTATION TRANSPORTATION_TOLLS]
        elsif description.match?(/amtrak/i)
          %w[TRANSPORTATION TRANSPORTATION_PUBLIC_TRANSIT]
        else
          %w[TRAVEL TRAVEL_OTHER_TRAVEL]
        end
      end

      def self.classify_auto_category(description)
        if description.match?(/toll/i) || description.match?(/bridge/i)
          %w[TRANSPORTATION TRANSPORTATION_TOLLS]
        elsif description.match?(/sec.*of.*state/i)
          %w[GOVERNMENT_AND_NON_PROFIT
             GOVERNMENT_AND_NON_PROFIT_GOVERNMENT_DEPARTMENTS_AND_AGENCIES]
        else
          %w[GENERAL_SERVICES GENERAL_SERVICES_AUTOMOTIVE]
        end
      end
    end
  end
end
