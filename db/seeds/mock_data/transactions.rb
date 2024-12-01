require 'factory_bot'
FactoryBot.find_definitions unless FactoryBot.factories.registered?(:transaction)

class TransactionGenerator
  ACCOUNT_TYPES = {
    credit: [
      { name: 'Chase Credit Card', sub_type: 'credit_card' },
      { name: 'AMEX Credit Card', sub_type: 'credit_card' },
      { name: 'Capital One Credit Card', sub_type: 'credit_card' }
    ],
    depository: [
      { name: 'Ally Bank Checking', sub_type: 'checking' }
    ],
    loan: [
      { name: 'Chase Home Mortgage', sub_type: 'mortgage' }
    ],
    investment: [
      { name: 'Vanguard Brokerage Account', sub_type: 'brokerage' }
    ]
  }
  NON_RECURRING_TRANSACTION_CATEGORIES = {
    FOOD_AND_DRINK_RESTAURANT: ['Chipotle', 'Starbucks', "McDonald's", 'Jets Pizza', "Hot Pot"],
    ENTERTAINMENT_TV_AND_MOVIES: ['Netflix', 'HBO Max', 'Movie Theater'],
    ENTERTAINMENT_MUSIC_AND_AUDIO: ['Spotify', 'Concert Venue'],
    TRAVEL_FLIGHTS: ['Delta', 'United Airlines'],
    TRANSPORTATION_TAXIS_AND_RIDE_SHARES: ['Uber', 'Lyft'],
    TRAVEL_LODGING: ['Airbnb', 'Booking.com'],
    GENERAL_MERCHANDISE_SUPERSTORES: ['Amazon', 'Best Buy', 'Walmart', 'Nordstrom', 'Target'],
    TRANSPORTATION_GAS: ['Speedway', 'Shell', 'Valero'],
    TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS: ['Investment Transfer'],
  }
  RECURRING_TRANSACTION_CATEGORIES = {
    LOAN_PAYMENTS_MORTGAGE_PAYMENT: ['Chase Mortgage'],
    FOOD_AND_DRINK_GROCERIES: ['Whole Foods', 'Kroger', 'Meijer', "Trader Joe's"],
    RENT_AND_UTILITIES_GAS_AND_ELECTRICITY: ['DTE Energy'],
    RENT_AND_UTILITIES_INTERNET_AND_CABLE: ['Youtube TV', 'Comcast'],
    RENT_AND_UTILITIES_WATER: ['Water Company'],
    INCOME_WAGES: ['Company Payroll'],
    GENERAL_SERVICES_INSURANCE: ['Geico'],
    LOAN_PAYMENTS_CAR_PAYMENT: ['Ford Credit']
  }
  PAYMENT_CHANNELS = ['in store', 'online', 'mobile']
  ACCOUNT_TYPES_WITH_RECURRING_TRANSACTIONS = ['checking', 'credit_card']

  def initialize(user)
    @user = user
    @accounts = create_accounts
    @start_date = Date.current - 1.year
    @end_date = Date.current
    @plaid_categories = PlaidCategory.all.to_a
  end

  def populate_data(total_transactions)
    transactions_per_account = total_transactions / @accounts.length

    @accounts.each do |account|
      generate_recurring_transactions(account, recurring_monthly_transaction_categories(account), monthly_dates)
      generate_recurring_transactions(account, recurring_biweekly_transaction_categories(account), biweekly_dates)
      generate_recurring_transactions(account, recurring_weekly_transaction_categories(account), weekly_dates)
      create_balances(account)

      next unless ACCOUNT_TYPES_WITH_RECURRING_TRANSACTIONS.include?(account.account_sub_type)

      category_multipliers = determine_category_multipliers(account)
      transactions_per_account.times { generate_transaction(account, category_multipliers) }
    end
  end

  private

  def create_accounts
    accounts = []
    
    ACCOUNT_TYPES.each do |type, account_details|
      account_details.each do |detail|
        accounts << FactoryBot.create(:account, 
          user: @user, 
          name: detail[:name], 
          account_type: type, 
          account_sub_type: detail[:sub_type],
          official_name: detail[:name]
        )
      end
    end
    
    accounts
  end

  def generate_recurring_transactions(account, categories, dates)
    categories.each do |category|
      dates.each do |date|
        FactoryBot.create(:transaction,
          user: @user,
          account: account,
          description: RECURRING_TRANSACTION_CATEGORIES[category].sample,
          amount: generate_transaction_amount(category),
          date: date,
          payment_channel: PAYMENT_CHANNELS.sample,
          pending: generate_pending(date),
          category_confidence: ['HIGH', 'MEDIUM', 'LOW'].sample,
          plaid_category_id: get_plaid_category_id(category)
        )
      end
    end
  end

  def generate_transaction(account, category_multipliers)
    category = choose_category(category_multipliers)
    merchants = NON_RECURRING_TRANSACTION_CATEGORIES[category]
    
    date = generate_date
    FactoryBot.create(:transaction,
      user: @user,
      account: account,
      description: "#{merchants.sample}",
      merchant_name: merchants.sample,
      amount: generate_transaction_amount(category),
      date: date,
      payment_channel: PAYMENT_CHANNELS.sample,
      pending: generate_pending(date),
      category_confidence: ['HIGH', 'MEDIUM', 'LOW'].sample,
      plaid_category_id: get_plaid_category_id(category)
    )
  end

  def create_balances(account)
    amount_fn = case account.account_sub_type
    when 'credit_card'
      lambda { |_| rand(30.0..750.0) }
    when 'checking'
      lambda { |_| rand(500.0..10_000.0) }
    when 'mortgage'
      lambda { |c| 150_000.0 - (c * 962.6) }
    when 'brokerage'
      lambda { |c| 200_000.0 + (c * rand(0.5..1.0)) * 1_500.0 }
    end

    monthly_dates.reverse.each_with_index do |date, idx|
      Balance.create!(
        account: account,
        amount: amount_fn.call(idx).round(2),
        created_at: date
      )
    end
  end

  def generate_transaction_amount(category)
    case category
    when :LOAN_PAYMENTS_MORTGAGE_PAYMENT
      1500.0
    when :LOAN_PAYMENTS_CAR_PAYMENT
      450.0
    when :GENERAL_SERVICES_INSURANCE
      250.0
    when :INCOME_WAGES
      -3000.0
    when :TRANSFER_IN_INVESTMENT_AND_RETIREMENT_FUNDS
      rand(500.0..5000.0).round(2)
    when :RENT_AND_UTILITIES_INTERNET_AND_CABLE, :RENT_AND_UTILITIES_WATER, :RENT_AND_UTILITIES_GAS_AND_ELECTRICITY
      rand(50.0..400.0).round(2)
    when :FOOD_AND_DRINK_GROCERIES
      rand(75.0..200.0).round(2)
    when :FOOD_AND_DRINK_RESTAURANT
      rand(10.0..100.0).round(2)
    else
      rand(5.0..250.0).round(2)
    end
  end

  def determine_category_multipliers(account)
    case account.account_sub_type
    when 'credit_card'
      { 
        FOOD_AND_DRINK_RESTAURANT: 0.25, 
        GENERAL_MERCHANDISE_SUPERSTORES: 0.25, 
        TRAVEL_FLIGHTS: 0.1, 
        ENTERTAINMENT_TV_AND_MOVIES: 0.1, 
        ENTERTAINMENT_MUSIC_AND_AUDIO: 0.1,
        TRAVEL_LODGING: 0.05,
        TRANSPORTATION_GAS: 0.05,
        TRANSPORTATION_TAXIS_AND_RIDE_SHARES: 0.05,
        TRANSFER_OUT_INVESTMENT_AND_RETIREMENT_FUNDS: 0.05 
      }
    else
      {}
    end
  end

  def recurring_monthly_transaction_categories(account)
    return [] unless account.account_sub_type == 'checking'

    [
      :LOAN_PAYMENTS_MORTGAGE_PAYMENT,
      :RENT_AND_UTILITIES_GAS_AND_ELECTRICITY,
      :RENT_AND_UTILITIES_INTERNET_AND_CABLE,
      :RENT_AND_UTILITIES_WATER,
      :GENERAL_SERVICES_INSURANCE,
      :LOAN_PAYMENTS_CAR_PAYMENT
    ]
  end

  def recurring_biweekly_transaction_categories(account)
    return [] unless account.account_sub_type == 'checking'

    [:INCOME_WAGES]
  end

  def recurring_weekly_transaction_categories(account)
    return [] unless account.account_sub_type == 'credit_card'

    [:FOOD_AND_DRINK_GROCERIES]
  end

  def get_plaid_category_id(category)
    @plaid_categories.find { |c| c.detailed_category == category.to_s }.id
  end

  def choose_category(category_multipliers)
    weighted_categories = category_multipliers.map do |category, weight|
      [category] * (weight * 100).to_i
    end.flatten

    weighted_categories.sample || NON_RECURRING_TRANSACTION_CATEGORIES.keys.sample
  end

  def generate_date
    rand(@start_date..@end_date)
  end

  def generate_pending(date)
    date.between?(Date.current - 4.days, Date.current)
  end

  def monthly_dates
    day_of_month = rand(1..28)
    (1..12).map do |delta|
      prev_date = Date.current - delta.month
      Date.new(prev_date.year, prev_date.month, day_of_month)
    end
  end

  def biweekly_dates
    offset = rand(0..13)
    (1..26).map do |delta|
      Date.current - delta.weeks - offset.days
    end
  end

  def weekly_dates
    offset = rand(0..6)
    (1..52).map do |delta|
      Date.current - delta.weeks - offset.days
    end
  end
end

generator = TransactionGenerator.new(User.last)
generator.populate_data(500)
