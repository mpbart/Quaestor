module HackerNews
  class Link
    
    attr_accessor :title, :url

    def initialize(raw_link)
      @title = raw_link.title
      @url = sanitize(raw_link.url)
    end

    private

    def sanitize(url)
      URI(url).host
    end

  end
end
