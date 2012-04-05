require 'singleton'

class Broker
  MESSAGE_PREFIX = "broker:message"
  QUEUE_KEY = 'broker:queue'

  include Singleton

  def initialize(redis = $redis)
    @redis = redis
  end

  # Publishes given action to publish queue.
  #
  # @param [String] action Action name
  # @param [Object] data Action related data
  def publish(action, data = nil)
    key = action_to_key action
    value = { action: key, data: data.to_s }
    @redis.rpush(QUEUE_KEY, value.to_json)
  end

  # Publishes all messages in publish queue.
  def flush
    return unless is_runner_listening?
    while message = @redis.lpop(QUEUE_KEY)
      message = ActiveSupport::JSON.decode message
      channel = "#{MESSAGE_PREFIX}:#{message["action"]}"
      puts "publishing to channel #{channel}"
      @redis.publish channel, message["data"].to_s
    end
  end

  private

  def action_to_key(action)
    action.to_s
  end

  def is_runner_listening?
    @redis.get(ServiceRunner::SERVICE_RUNNER_KEY) == "on"
  end
end
