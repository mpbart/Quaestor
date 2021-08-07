module CsvImport
  module Constants
    class Mint

      def map_category(category, description)
        self.class.mappings.dig(category).call(description)
      end

      def self.mappings
        @mappings ||= begin
          conversions = {
            'Auto Insurance' => 'Insurance',
            'Auto Payment' => 'Payment',
            'Gas & Fuel' => 'Gas Stations',
            'Parking' => 'Parking',
            'Public Transportation' => 'Public Transportation Services',
            'Service & Parts' => 'Car Service',
            'Home Phone' => 'Mobile Phone',
            'Internet' => 'Internet Services',
            'Mobile Phone' => 'Mobile Phone',
            'Television' => 'Utilities',
            'Utilities' => 'Utilities',
            'Advertising' => 'Advertising and Marketing',
            'Legal' => 'Legal',
            'Office Supplies' => 'Office Supplies',
            'Printing' => 'Printing and Publishing',
            'Shipping' => 'Shipping and Freight',
            'Books & Supplies' => 'Bookstores',
            'Student Loan' => 'Loan',
            'Tuition' => 'Colleges and Universities',
            'Amusement' => 'Entertainment',
            'Arts' => 'Arts and Entertainment',
            'Movies & DVDs' => 'Movie Theatres',
            'Music' => 'Music, Video and DVD',
            'Newspapers & Magazines' => 'Newsstands',
            'Relaxation' => 'Entertainment',
            'Sports Tickets' => 'Sports Venues',
            'ATM Fee' => 'Bank Fee',
            'Bank Fee' => 'Bank Fee',
            'Finance Charge' => 'Bank Fee',
            'Late Fee' => 'Bank Fee',
            'Service Fee' => 'Bank Fee',
            'Trade Commissions' => 'Bank Fee',
            'Financial Advisor' => 'Financial Planning and Investments',
            'Life Insurance    ' => 'Insurance',
            'Alcohol & Bars' => 'Bar',
            'Coffee Shops' => 'Coffee Shop',
            'Fast Food' => 'Fast Food',
            'Groceries' => 'Supermarkets and Groceries',
            'Restaurants' => 'Restaurants',
            'Lunch' => 'Lunch',
            'Charity' => 'Charities and Non-Profits',
            'Gift' => 'Gift and Novelty',
            'Engagement Ring' => 'Engagement Ring',
            'Dentist' => 'Dentists',
            'Doctor' => 'Healthcare',
            'Eyecare' => 'Glasses and Optometrist',
            'Gym' => 'Gyms and Fitness Centers',
            'Health Insurance' => 'Insurance',
            'Pharmacy' => 'Pharmacies',
            'Sports' => ->(description) { classify_sports_category(description) },
            'Furnishings' => 'Furniture and Home Decor',
            'Home Improvement' => 'Home Improvement',
            'Home Insurance' => 'Insurance',
            'Home Services' => 'Home Improvement',
            'Home Supplies' => 'Home Improvement',
            'Lawn & Garden' => 'Lawn & Garden',
            'Mortgage & Rent' => ->(description) { classify_mortgage_and_rent_category(description) },
            'Down Payment' => 'Down Payment',
            'Move in fee' => 'Move in Fee',
            'Moving Expenses' => 'Movers',
            'Bonus' => 'Bonus',
            'Interest Income' => 'Interest Earned',
            'Paycheck' => 'Payroll',
            'Reimbursement' => 'Payroll',
            'Rental Income' => 'Rent',
            'Returned Purchase' => 'Payment',
            'Buy' => 'Excluded',
            'Deposit' => 'Deposit',
            'Dividend & Cap Gains' => 'Financial Planning and Investments',
            'Sell' => 'Excluded',
            'Withdrawal' => 'Excluded',
            'Allowance' => 'Excluded',
            'Baby Supplies' => 'Children',
            'Babysitter & Daycare' => 'Children',
            'Child Support' => 'Children',
            'Kids Activities' => 'Children',
            'Toys' => 'Toys',
            'Loan Fees and Charges' => 'Loan',
            'Loan Insurance' => 'Loan',
            'Loan Interest' => 'Loan',
            'Loan Payment' => 'Payment',
            'Loan Principal' => 'Payment',
            'Wedding' => 'Wedding and Bridal',
            'Hair' => 'Hair Salons and Barbers',
            'Laundry' => 'Laundry and Garment Services',
            'Spa & Massage' => 'Spas',
            'Pet Food & Supplies' => 'Pets',
            'Pet Grooming' => 'Pets',
            'Veterinary' => 'Veterinarians',
            'Books' => 'Bookstores',
            'Clothing' => 'Clothing and Accessories',
            'Electronics & Software' => 'Computers and Electronics',
            'Hobbies' => 'Hobby and Collectibles',
            'Sporting Goods' => 'Sporting Goods',
            'Federal Tax' => 'Taxes',
            'Local Tax' => 'Taxes',
            'Property Tax' => 'Taxes',
            'Sales Tax' => 'Taxes',
            'State Tax' => 'Taxes',
            'Credit Card Payment' => 'Excluded',
            'Transfer for Cash Spending' => 'Excluded',
            'Air Travel' => 'Airlines and Aviation Services',
            'Hotel' => 'Hotels and Motels',
            'Rental Car & Taxi' => ->(description) { classify_rental_car_and_taxi_category(description) },
            'Vacation' => 'Vacation',
            'Cash & ATM' => 'ATM',
            'Check' => 'Check',
            'Income' => 'Income',
            'Food & Dining' => 'Food and Drink',
            'Entertainment' => 'Arts and Entertainment',
            'Taxes' => 'Taxes',
            'Shopping' => 'Shops',
            'Fees & Charges' => 'Bank Fees',
            'Transfer' => 'Transfer',
            'Travel' => 'Travel',
            'Business Services' => 'Business Services',
            'Health & Fitness' => 'Gyms and Fitness Centers',
            'Auto & Transport' => 'Tolls and Fees',
            'Personal Care' => 'Personal Care',
            'Investments' => 'Excluded',
            'Financial' => 'Uncategorized',
            'Education' => 'Education',
            'Rent application fee' => 'Bank Fee',
            'Home' => 'Excluded',
            'Misc Expenses' => 'Excluded',
            'Hide from Budgets & Trends' => 'Excluded',
            'Uncategorized' => 'Uncategorized',
          }

          conversions.each do |_k, value|
            next if value.respond_to?(:call)

            conversions[_k] = ->(_) { value }
          end

          conversions
        end
      end

      private

      def self.classify_sports_category(description)
        if description.match?(/golf/i)
          'Golf'
        else
          'Soccer'
        end
      end

      def self.classify_mortgage_and_rent_category(description)
        if description.match?(/citizens/i)
          'Loans and Mortgages'
        else
          'Rent'
        end
      end

      def self.classify_rental_car_and_taxi_category(description)
        if description.match?(/hertz/i) || description.match?(/avis/i) || description.match?(/expedia/i) || description.match?(/alamo/i)
          'Car and Truck Rentals'
        elsif description.match?(/uber/i) || description.match?(/lyft/i)
          'Ride Share'
        else
          'Taxi'
        end
      end

    end
  end
end
