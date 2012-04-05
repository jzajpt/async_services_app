class Activity
  attr_accessor :action, :originator

  class << self
    def publish(action, originator)
      Broker.instance.publish action, originator.to_json
    end
  end
end
