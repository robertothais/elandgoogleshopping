require 'dalli'

require './fetcher'

cache = Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || 'localhost:11211').split(","),
  {:username => ENV["MEMCACHIER_USERNAME"],
   :password => ENV["MEMCACHIER_PASSWORD"],
   :failover => true,
   :socket_timeout => 1.5,
   :socket_failure_delay => 0.2
  }
)

get '/fetch' do
  fetcher = Fetcher.new
  fetcher.fetch!
  cache.set('feed', fetcher.to_feed)
  'ok'
end

get '/feed.xml' do
  cache.get('feed')
end