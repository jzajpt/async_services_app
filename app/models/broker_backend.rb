require 'singleton'

class BrokerBackend
  include Singleton

  attr_accessor :redis

  def initialize
    @redis = $redis
  end

  # Subscribe for receiving given actions.
  #
  # @param [Array] actions Actions to subscribe to
  def subscribe(*actions, &block)
    @redis.psubscribe(*map_actions(actions)) do |on|
      on.pmessage do |_, channel, msg|
        action = extract_action channel
        block.call action, msg
      end
    end
  end

  # Unsubscribe from receiving given actions.
  #
  # @param [Array] actions Actions to unsuscribe from
  def unsubscribe(*actions)
    @redis.punsubscribe(*map_actions(actions))
  end

  private

  def map_actions(actions)
    actions.map do |action|
      "#{Broker::MESSAGE_PREFIX}:#{action}"
    end
  end

  def extract_action(channel)
    channel.match(/^#{Broker::MESSAGE_PREFIX}:(.+)$/)[1]
  end
end
