
$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp'
require 'rhcp/tests_for_brokers'

class DispatchingBrokerTest < Test::Unit::TestCase

  include TestsForBrokers

  def setup
    @broker = RHCP::Broker.new()

    @broker2 = RHCP::Broker.new()

    @test_broker = RHCP::DispatchingBroker.new()
    @test_broker.add_broker(@broker)
    @test_broker.add_broker(@broker2)
  end

  def test_duplicate_commands
    @broker.register_command RHCP::Command.new("funky_stuff", "just testing (broker1)", lambda{})
    assert_equal 1, @test_broker.get_command_list().size()
    @broker2.register_command RHCP::Command.new("echo", "says hello (broker2)", lambda{})
    @broker2.register_command RHCP::Command.new("help", "is no help at all (broker2)", lambda{})
    @broker2.register_command RHCP::Command.new("red button", "don't press it (broker2)", lambda{})
    assert_equal 4, @test_broker.get_command_list().size()

    assert_raise(RHCP::RhcpException) { @test_broker.add_broker(@broker2) }
    #assert_equal 4, @test_broker.get_command_list().size()
  end
  
end

