require "minitest/autorun"
require "redis"
require "active_support/json"

require_relative "../../lib/service"

describe Service do
  let(:broker) { MiniTest::Mock.new }
  subject { Service.new broker }

  describe "#subscribe" do
    it "calls subscribe with class subscriptions on broker" do
      Service.instance_variable_set :@subscriptions, ["test:pukka"]
      broker.expect :subscribe, nil, ["test:pukka"]
      subject.subscribe
      broker.verify
    end
  end

  describe "#unsubscribe" do
    it "calls unsubscribe with class subscriptions on broker" do
      Service.instance_variable_set :@subscriptions, ["test:pukka"]
      broker.expect :unsubscribe, nil, ["test:pukka"]
      subject.unsubscribe
      broker.verify
    end
  end

  describe ".subscribe_to" do
    it "sets class instance variable @subscriptions to given value" do
      Service.subscribe_to("test:pukka", "test:ohai")
      Service.instance_variable_get(:@subscriptions).must_equal ["test:pukka", "test:ohai"]
    end
  end
end
