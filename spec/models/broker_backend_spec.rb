require "minitest/autorun"
require "redis"
require "active_support/json"

$redis = Redis.new(:host => 'localhost', :port => 6379)
require_relative "../../app/models/broker"
require_relative "../../app/models/broker_backend"

def subscribe_in_thread(subject, *messages)
  Thread.new do
    subject.redis = Redis.new(:host => 'localhost', :port => 6379)
    Thread.current["messages"] = []
    subject.subscribe(*messages) do |message, data|
      Thread.current["messages"] << [message, data]
    end
  end
end

describe BrokerBackend do
  subject { BrokerBackend.instance }

  describe "#subscribe" do
    describe "with asterisk in the action name" do
      it "calls given block when appropriate message is published" do
        subscribe_thread = subscribe_in_thread subject, "test:*"
        sleep 1 # Wait for thread
        $redis.publish "broker:message:test:pukka", "oh my"
        Timeout::timeout(3) do
          while subscribe_thread["messages"].empty?;  end
          subscribe_thread["messages"].must_equal [["test:pukka", "oh my"]]
        end
      end
    end

    describe "with 1 action" do
      it "calls given block when given message is published" do
        subscribe_thread = subscribe_in_thread subject, "test:pukka"
        sleep 1 # Wait for thread
        $redis.publish "broker:message:test:pukka", "oh my"
        sleep 2
        subscribe_thread["messages"].must_equal [["test:pukka", "oh my"]]
      end
    end

    describe "with 2 actions" do
      it "calls given block when any of given messages is published" do
        subscribe_thread = subscribe_in_thread subject, "test:pukka", "test:ohai"
        sleep 1 # Wait for thread
        $redis.publish "broker:message:test:ohai", "oh my"
        $redis.publish "broker:message:test:pukka", "oh no"
        sleep 2
        subscribe_thread["messages"].must_equal [["test:ohai", "oh my"],
                                                 ["test:pukka", "oh no"]]
      end
    end
  end

  describe "#unsubscribe" do
    it "unsubscribes from redis" do
      subscribe_thread = subscribe_in_thread subject, "test:pukka"
      sleep 1 # Wait for thread
      $redis.publish "broker:message:test:pukka", "oh my"
      subject.unsubscribe "test:pukka"
      $redis.publish "broker:message:test:pukka", "oh noes!"
      Thread.kill(subscribe_thread)
      sleep 2
      subscribe_thread["messages"].must_equal [["test:pukka", "oh my"]]
    end
  end
end
