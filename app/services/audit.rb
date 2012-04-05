class Audit < Service
  subscribe_to "*"

  def perform(channel, data)
    redis = Redis.new(:host => 'localhost', :port => 6379)
    redis.rpush "activities:audit", channel
  end
end
