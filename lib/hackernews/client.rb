require 'hackernews_ruby'

module HackerNews
  class Client

    def get_links(number:)
      HackernewsRuby::Client.new.top.fist(number)
    end

  end
end
