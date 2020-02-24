require 'twitter/client'
require 'hackernews/client'

class HomeController < ActionController::Base
  def load_tweets
    client = PersonalCrm::Twitter::Client.intialize_from_config
    client.load_tweets(number: 5)
  end

  def load_hackernews_links
    client = PersonalCrm::HackerNews::Client.initialize_from_config
    client.load_links(number: 5)
  end
end
