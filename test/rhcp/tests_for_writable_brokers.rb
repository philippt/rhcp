module TestsForWritableBrokers

def test_register_commands
    assert_not_nil @broker
    commands = @broker.get_command_list
    assert_not_nil commands
    assert_equal 0, commands.size

    command = RHCP::Command.new("test", "a test command", lambda {})
    @broker.register_command(command)

    commands = @test_broker.get_command_list
    assert_equal 1, commands.size
    assert_equal command, commands["test"]
  end

  def test_register_duplicate
    @broker.register_command RHCP::Command.new("test", "a test command", lambda {})
    assert_raise(RHCP::RhcpException) { @broker.register_command RHCP::Command.new("test", "a command with the same name", lambda {}) }
  end

end