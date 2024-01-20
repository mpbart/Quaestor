# frozen_string_literal: true

require 'json'

class ConfigReader
  def self.for(client_name)
    config_file[client_name]
  end

  def self.config_file
    File.open(Rails.root.join('config.json'), 'r') do |file|
      JSON.parse(file.read)
    end
  end
end
