require 'my_twitter/client'
require 'hackernews/client'

class HomeController < ActionController::Base
  def index
    @links = load_hackernews_links
    @tweets = load_tweets
  end

  def load_tweets
    client = MyTwitter::Client.initialize_from_config
    client.get_tweets(number: 5)
  end

  def load_hackernews_links
    client = HackerNews::Client
    client.links(number: 5)
  end
end
