# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require_relative 'boot'

require 'rails/all'
require 'devise'
require 'will_paginate'
require 'cocoon'
require 'importmap-rails'
require 'turbo-rails'
require 'sprockets/railtie'
require 'acts_as_paranoid'
require 'sidekiq'
require 'haml'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.

module Quaestor
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1
    config.time_zone = 'America/Detroit'
    config.action_view.form_with_generates_remote_forms = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
