require 'twitter/client'
require 'hackernews/client'

class HomeController < ActionController::Base
  def index
    @links = load_hackernews_links
  end

  def load_tweets
    client = Twitter::Client.initialize_from_config
    client.load_tweets(number: 5)
  end

  def load_hackernews_links
    client = HackerNews::Client
    client.links(number: 5)
  end
end
