require 'redis'

connection_options = {url: ENV['REDIS_URL'], timeout: 10}
REDIS = Redis.new(**connection_options)
