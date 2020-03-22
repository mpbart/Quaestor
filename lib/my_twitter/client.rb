require 'twitter'
require 'config_reader'
require 'constants'

module MyTwitter
  class Client
    
    attr_reader :client

    def initialize(config_reader)
      @client = Twitter::REST::Client.new do |config|
        config.consumer_key        = config_reader['consumer_key']
        config.consumer_secret     = config_reader['consumer_secret']
        config.access_token        = config_reader['access_token']
        config.access_token_secret = config_reader['access_token_secret']
      end
    end

    def self.initialize_from_config
      config_reader = ConfigReader.for(Constants.twitter)
      new(config_reader)
    end

    def get_tweets(number:)
      client.home_timeline.first(number)        
    end

  end
end
