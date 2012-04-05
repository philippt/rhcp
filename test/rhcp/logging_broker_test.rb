$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp'

require 'test/unit'
require 'rhcp/tests_for_brokers'
require 'rhcp/tests_for_writable_brokers'

class LoggingBrokerTest < Test::Unit::TestCase

  include TestsForBrokers
  include TestsForWritableBrokers

  def setup
    broker = RHCP::Broker.new()

    @broker = broker
    @test_broker = RHCP::LoggingBroker.new(broker)
  end

end