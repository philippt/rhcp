$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp'

require 'test/unit'
require 'rhcp/tests_for_brokers'

class ContextAwareBrokerTest < Test::Unit::TestCase

  include TestsForBrokers

  def setup
    broker = RHCP::Broker.new()
    
    @broker = broker
    @test_broker = RHCP::Client::ContextAwareBroker.new(broker)
  end

  def add_context_commands
    @switch_host = RHCP::Command.new("switch_host", "modifies the context",
      lambda { |request, response|
        response.set_context({'host' => request.get_param_value('new_host')})
      }
    )
    @switch_host.add_param(RHCP::CommandParam.new("new_host", "the new host name",
        {
          :mandatory => true,
          :is_default_param => true,
        }
    ))
    @broker.register_command @switch_host

    @host_command = RHCP::Command.new("say_hello", "uses context",
      lambda { |request, response|
        "hello from " + request.get_param_value('the_host')
      }
    )
    @host_command.add_param(RHCP::CommandParam.new("the_host", "the host name (should be taken from context)",
        {
          :mandatory => true,
          :is_default_param => true,
          :autofill_context_key => 'host'
        }
    ))
    @broker.register_command @host_command

    context_command = RHCP::Command.new("let_explode_host", "available only in host context",
      lambda { |request, response|
        "kaboom."
      }
    )
    context_command.enabled_through_context_keys = ['host']
    @broker.register_command context_command
  end

  def test_context_aware_command_list
    add_context_commands

    assert_equal 2, @test_broker.get_command_list().size
    @test_broker.context.cookies['host'] = 'moriturus'
    assert_equal 3, @test_broker.get_command_list().size
  end

  def test_context_setting_command
    add_context_commands

    request = RHCP::Request.new(@switch_host, {'new_host' => 'lucky bastard'})
    @test_broker.execute(request)
    assert_equal 'lucky bastard', @test_broker.context.cookies['host']
    request = RHCP::Request.new(@host_command, {})
    assert_equal "hello from lucky bastard", @test_broker.execute(request).data
  end

  def test_invoke_twice
    add_context_commands

    @test_broker.context.cookies['host'] = 'the_host'
    request = RHCP::Request.new(@host_command)
    response = @test_broker.execute(request)
    assert_equal "hello from the_host", response.data

    response = @test_broker.execute(request)
    assert_equal "hello from the_host", response.data
  end
end
