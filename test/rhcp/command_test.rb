$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp'

class CommandTest < Test::Unit::TestCase
  
  def command_method(request, response)
    first_param = request.get_param_value("first_param")
    puts "just testing : #{first_param}"    
    first_param.reverse
  end
  
  def command_method_with_error(request, response)
    raise "got a problem here!"
  end
  
  def test_construction
    command = RHCP::Command.new("test", "a command for testing", self.method(:command_method))
    assert_not_nil command
    assert_equal "test", command.name
    assert_equal "a command for testing", command.description
    
    assert_not_nil command.params
    assert_instance_of Array, command.params
    assert_equal 0, command.params.size
    
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    command.add_param(RHCP::CommandParam.new("second_param", "this is the second param"))
    assert_equal 2, command.params.size
    first_param = command.get_param("first_param")
    assert_not_nil first_param
    assert_equal "first_param", first_param.name
    assert_equal "this is the first param", first_param.description
    assert_raise(RHCP::RhcpException) { command.get_param("does not exist") }
  end
  
  def test_execute_request
    command = RHCP::Command.new("test", "a command for testing", self.method(:command_method))
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    request = RHCP::Request.new(command, { "first_param" => [ "the_value" ] })
    response = command.execute_request(request) 
    assert_equal "the_value".reverse, response.data
    assert_equal RHCP::Response::Status::OK, response.status
  end
  
  def test_execute_error
    command = RHCP::Command.new("not working", "told you so", self.method(:command_method_with_error))
    request = RHCP::Request.new(command, {})
    response = command.execute_request(request)
    assert_equal RHCP::Response::Status::ERROR, response.status
  end
  
  def test_execute
    command = RHCP::Command.new("test", "a command for testing", self.method(:command_method))
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    response = command.execute({"first_param" => "thing"})
    assert_equal "thing".reverse, response.data    
  end
  
  def test_duplicate_params
    command = RHCP::Command.new("test_duplicate", "command for testing param duplicates", lambda {})
    command.add_param(RHCP::CommandParam.new("first_param", "first param"))
    assert_raise(RuntimeError) { command.add_param(RHCP::CommandParam.new("first_param", "i am a duplicate")) }
  end
  
  # it should not be possible to add more than one default param
  def test_multiple_default_params
    command = RHCP::Command.new("test", "command for testing multiple default params", lambda {})
    command.add_param RHCP::CommandParam.new("first_param", "first param", 
        {
          :is_default_param => true
        }
    )
    assert_raise(RHCP::RhcpException) {
      command.add_param RHCP::CommandParam.new("second_param", "second default param", 
        {
          :is_default_param => true
        }
      ) 
    }
  end
  
  def test_get_default_param
    command = RHCP::Command.new("test_duplicate", "command for testing get_default_param", lambda {})
    assert_nil command.default_param
    the_param = RHCP::CommandParam.new("first_param", "first param", 
        {
          :is_default_param => true
        }
    )
    command.add_param the_param
    assert_equal the_param, command.default_param
  end
  
  def test_enabled_through_context
    command = RHCP::Command.new("context_test", "testing the context", lambda {
      |req,res|
      puts "While I think there could be something important to say right now, I just cannot remember what it might have been..."
      res.result_text = "the test is working"
    })

    # by default, commands should be enabled even with an empty context
    assert command.is_enabled?
    assert command.is_enabled?({})

    # if we pass an empty list of context_keys, the command should be disabled
    command.enabled_through_context_keys = []
    assert ! command.is_enabled?

    context = RHCP::Context.new()
    context.cookies['ankh'] = 'morpork'
    
    command.enabled_through_context_keys = ['host']
    assert ! command.is_enabled?
    assert ! command.is_enabled?(context)
    context.cookies['host'] = 'deepthought'
    assert command.is_enabled?(context)
  end

    def test_invalid_param_name
    command = RHCP::Command.new("test", "another test", lambda {})
    command.add_param(RHCP::CommandParam.new("real_param", "this param does exist"))
    
    assert_raise(RHCP::RhcpException) {
      request = RHCP::Request.new(command, {
          "does_not_exist" =>  [ "single value for non-existing param" ]
      })
      command.execute_request(request)
    }
  end

  def test_invalid_param_values
    command = RHCP::Command.new("test", "another test", lambda {})
    command.add_param(RHCP::CommandParam.new("real_param", "this param does exist"))
    request = RHCP::Request.new(command, {
          "real_param" =>  [ "value for the real param", "another value for the real param" ]
    })
    assert_raise(RHCP::RhcpException) { command.execute_request(request) }
  end

  def test_missing_mandatory_param
    command = RHCP::Command.new("test", "another test", lambda {})
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param", { :mandatory => true }))
    command.add_param(RHCP::CommandParam.new("second_param", "this param is optional", { :mandatory => false }))

    assert_raise(RHCP::RhcpException) {
      request = RHCP::Request.new(command, {})
      command.execute_request(request)
    }
  end

end

