class Service
  class << self
    attr_reader :subscriptions

    def subscribe_to(*actions)
      @subscriptions = actions
    end
  end

  def initialize(broker)
    @broker = broker
  end

  # Starts listening to subscribed actions.
  def subscribe
    @broker.subscribe(*self.class.subscriptions) do |channel, data|
      begin
        perform(channel, data)
      rescue => e
        puts "Exception #{e}"
      end
    end
  end

  def unsubscribe
    @broker.unsubscribe(*self.class.subscriptions)
  end

  def perform(channel, data)
  end
end
