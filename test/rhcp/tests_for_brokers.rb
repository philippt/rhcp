module TestsForBrokers

  def test_command_list_with_context
    command = RHCP::Command.new("test", "a test command that is enabled for hosts only", lambda {})
    command.enabled_through_context_keys = ['host']
    @broker.register_command command
    command2 = RHCP::Command.new("test2", "a test command should always be enabled", lambda {})
    @broker.register_command command2

    assert_equal 1, @test_broker.get_command_list().size()
    context = RHCP::Context.new()
    context.cookies['host'] = 'deepthought'
    assert_equal 2, @test_broker.get_command_list(context).size()
  end

    # it should not be possible to call get_command() for a command that is
  # disabled through the context
  def test_get_command_with_context
    command = RHCP::Command.new("test", "a test command that is enabled for hosts only", lambda {})
    command.enabled_through_context_keys = ['host']
    @broker.register_command command
    command2 = RHCP::Command.new("test2", "a test command should always be enabled", lambda {})
    @broker.register_command command2

    assert @test_broker.get_command("test2")
    assert_raise(RHCP::RhcpException) {
      @test_broker.get_command("test")
    }
    context = RHCP::Context.new()
    context.cookies['host'] = 'deepthought'
    assert @test_broker.get_command("test", context)
  end

  def test_get_lookup_values
    command = RHCP::Command.new("test", "a test command with lookup values", lambda {})
    command.add_param RHCP::CommandParam.new("first_param", "first param",
        {
          :is_default_param => true,
          :lookup_method => lambda {
            [ "wind", "sun", "boat" ]
          }
        }
    )
    command.add_param RHCP::CommandParam.new("second_param", "this param's lookup values depend on the first param",
        {
          :lookup_method => lambda { |request|
            $logger.debug "in lookup : #{request}"
            if request.has_param_value("first_param")
              request.get_param_value("first_param").map do |item|
                item.reverse
              end
            else
              [ "wind", "sun", "boat" ]
            end
          }
        }
    )
    command.add_param RHCP::CommandParam.new("host", "host dummy param",
      {
        :mandatory => false,
        :autofill_context_key => "host"
      }
    )
    command.add_param RHCP::CommandParam.new("third_param", "this param's lookup values depend on context",
        {
          :lookup_method => lambda { |request|
            result = []
            if request.has_param_value("host")
              1.upto(3) do |loop|
                result << request.get_param_value("host") + "_service#{loop}"
              end
            else
              result = [ "wind", "sun", "boat" ]
            end
            result
          }
        }
    )
    @broker.register_command command

    # no values collected so far, no context
    request = RHCP::Request.new(command, { })
    assert_equal [ "wind", "sun", "boat" ].sort, @test_broker.get_lookup_values(request, "first_param").sort
    assert_equal [ "wind", "sun", "boat" ].sort, @test_broker.get_lookup_values(request, "second_param").sort
    # lookup values can depend on other params' values
#    context = RHCP::Context.new()
#    context.collected_values["first_param"] = "zaphod"
    request = RHCP::Request.new(command, { "first_param" => "wind" })
    assert_equal [ "dniw" ], @test_broker.get_lookup_values(request, "second_param")
    # or on the context
    request = RHCP::Request.new(command, {}, RHCP::Context.new({"host" => "endeavour"}))
    assert_equal [ "endeavour_service1", "endeavour_service2", "endeavour_service3" ].sort,
      @test_broker.get_lookup_values(request, "third_param").sort
  end

  def test_param_is_valid
    command = RHCP::Command.new("test", "a test command with lookup values", lambda {})
    command.add_param RHCP::CommandParam.new("first_param", "first param",
        {
          :is_default_param => true,
          :lookup_method => lambda {
            [ "wind", "sun", "boat" ]
          }
        }
    )
    @broker.register_command command

    request = RHCP::Request.new(command, {  })
    assert @test_broker.check_param_is_valid(request, "first_param", [ "wind" ])
    assert_raise(RHCP::RhcpException) {
      @test_broker.check_param_is_valid(request, "first_param", ["zaphod"])
    }
  end

  def test_param_is_valid_without_lookup_values
    command = RHCP::Command.new("test", "a test command with lookup values", lambda {})
    command.add_param RHCP::CommandParam.new("first_param", "first param",
        {
          :is_default_param => true,
        }
    )
    @broker.register_command command

    request = RHCP::Request.new(command, {  })
    assert @test_broker.check_param_is_valid(request, "first_param", [ "wind" ])
    assert @test_broker.check_param_is_valid(request, "first_param", ["zaphod"])
  end

  def test_mandatory_prefilled_params
    command = RHCP::Command.new("test_duplicate", "command for testing param duplicates", lambda {})
    command.add_param(RHCP::CommandParam.new("first_param", "first param", {
      :mandatory => false
    }))
    command.add_param(RHCP::CommandParam.new("second_param", "second param", {
      :mandatory => true
    }))
    command.add_param(RHCP::CommandParam.new("third_param", "third param", {
      :mandatory => true,
      :autofill_context_key => 'dessert'
    }))
    @broker.register_command command

    assert_equal ["second_param", "third_param"], @test_broker.get_mandatory_params("test_duplicate").map { |param| param.name }.sort()
    context = RHCP::Context.new()
    context.cookies['dessert'] = 'mascarpone'
    context.cookies['host'] = 'deepthought'
    assert_equal ["second_param"], @test_broker.get_mandatory_params("test_duplicate", context).map { |param| param.name }.sort()
    context.cookies.delete('dessert') #sigh
    #assert_equal ["second_param", "third_param"], command.get_mandatory_params(context).map { |param| param.name }.sort()
    assert_equal ["second_param", "third_param"], @test_broker.get_mandatory_params("test_duplicate", context).map { |param| param.name }.sort()
  end

  def test_execute
    command = RHCP::Command.new("test", "a command for testing", lambda { |request,response|
      first_param = request.get_param_value("first_param")
      puts "just testing : #{first_param}"
      first_param.reverse
    })
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    @broker.register_command command

    request = RHCP::Request.new(command, {"first_param" => "thing"})
    response = @test_broker.execute(request)
    assert_equal "thing".reverse, response.data
  end

  def test_execute_with_context
    command = RHCP::Command.new("testcontext", "a command for context testing", lambda { |request,response|
      first_param = request.get_param_value("first_param")
      puts "just testing : #{first_param}"      
      response.set_context({'end' => 'happy'})
      first_param.reverse
    })
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param", {
      :mandatory => true,
      :autofill_context_key => 'spooky'
    }))
    @broker.register_command command

    context = RHCP::Context.new({'spooky' => 'coincidence'})
    request = RHCP::Request.new(command, {}, context)
    response = @test_broker.execute(request)
    assert_equal "coincidence".reverse, response.data
  end

end