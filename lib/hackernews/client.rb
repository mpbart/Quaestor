require 'hackernews_ruby'
require 'hackernews/link'

module HackerNews
  class Client

    def self.links(number:)
      client.top_stories.first(number).map{ |id| individual_story_details(id) }
    end

    def self.individual_story_details(story_id)
      HackerNews::Link.new(client.get_item(story_id))
    end
    private_class_method :individual_story_details

    def self.client
      @client ||= HackernewsRuby::Client.new
    end
    private_class_method :client

  end
end
