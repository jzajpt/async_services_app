require "minitest/autorun"
require "redis"
require "active_support/json"

$redis = Redis.new(:host => 'localhost', :port => 6379)

require_relative "../../app/models/broker"

describe Broker do
  subject { Broker.instance }

  describe "#publish" do
    it "pushes a message to Redis" do
      subject.publish "action", "data"
      $redis.lpop("broker:queue").wont_be_empty
    end

    it "encodes action name and data into JSON object" do
      subject.publish "action", "data"
      data = ActiveSupport::JSON.decode $redis.lpop("broker:queue")
      data.must_equal({ "action" => "action", "data" => "data" })
    end
  end

  describe "#flush" do
    describe "when service runner is not running" do
      before do
        $redis.set "broker:service:runner", nil
      end

      it "returns nil" do
        subject.flush.must_be_nil
      end
    end

    describe "when service runner is running" do
      before do
        $redis.set "broker:service:runner", "on"
        $redis.del "broker:queue"
      end

      it "publishes each message from the queue" do
        $redis.rpush "broker:queue", '{"action":"test:pukka"}'
        $redis.rpush "broker:queue", '{"action":"test:killa"}'
        subscribe_thread = Thread.new do
          Thread.current["messages"] = []
          $redis.psubscribe("*") do |on|
            on.pmessage do |_, message|
              Thread.current["messages"] << message
            end
          end
        end
        subject.flush
        sleep 1
        message_names = subscribe_thread["messages"]
        message_names.must_equal ["broker:message:test:pukka", "broker:message:test:killa"]
      end
    end
  end
end
