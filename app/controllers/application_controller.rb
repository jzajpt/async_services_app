class ApplicationController < ActionController::Base
  protect_from_forgery

  after_filter :flush_queue

  def flush_queue
    Broker.instance.flush
  end
end
