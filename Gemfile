source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7'
# Use Puma as the app server
gem 'puma', '~> 6'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6'

# Javascript import maps for rails
gem 'importmap-rails', '~> 2'

# Turbo makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbo-rails', '~> 2'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'devise', '~> 4'

gem 'plaid', '~> 23'

gem 'pg'

gem 'attr_encrypted'

gem 'will_paginate', '~> 3.3'

gem 'cocoon'

gem 'sprockets', '~> 4'

gem 'acts_as_paranoid', '~> 0.9'

gem 'redis', '~> 5'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'database_cleaner-active_record'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'rails-controller-testing'
  gem 'rspec', '~> 3'
  gem 'rspec-rails', '~> 6.1'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'awesome_print'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'listen'
  gem 'pry'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'rubocop', '~> 1.60'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  # Easy installation and use of web drivers to run system tests with browsers
end
