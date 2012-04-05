$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'

require 'rhcp'
require 'rhcp/tests_for_brokers'
require 'rhcp/tests_for_writable_brokers'

class BrokerTest < Test::Unit::TestCase

  include TestsForBrokers
  include TestsForWritableBrokers

  def setup
    @broker = RHCP::Broker.new()
    @test_broker = @broker
  end

end
