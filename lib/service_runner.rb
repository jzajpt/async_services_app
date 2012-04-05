module ServiceRunner
  extend self

  SERVICE_RUNNER_KEY = "broker:service:runner"

  attr_reader :service_instances

  # Runs all services. Each services runs in a separate, forked
  # process with own subscribe loop.
  def run_all
    @service_instances = []
    Service.descendants.each do |klass|
      print "- running #{klass} service "
      fork do
        run_service(klass)
      end
      puts "."
    end
    $redis.set SERVICE_RUNNER_KEY, "on"
    Process.waitall
  end

  # Unsubscribes all services.
  def unsubscribe_all
    $redis.del SERVICE_RUNNER_KEY
    @service_instances.each do |instance|
      puts "unsubscribing #{instance}"
      instance.unsubscribe
    end
  end

  private

  def run_service(klass)
    instance = klass.new(BrokerBackend.instance)
    instance.subscribe
    @service_instances << instance
  end
end
