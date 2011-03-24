$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp'

require 'rubygems'
require 'json'

class RequestTest < Test::Unit::TestCase

  def test_construction
    command = RHCP::Command.new("test", "a test", nil)
    assert_raise(RHCP::RhcpException) { RHCP::Request.new(nil, Hash.new()) }
    request = RHCP::Request.new(command, Hash.new())
    assert_not_nil request
  end
  
  def test_get_param_value
    command = RHCP::Command.new("test", "a test", nil)
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    command.add_param(RHCP::CommandParam.new("second_param", "this is the second param", { :allows_multiple_values => true }))
    request = RHCP::Request.new(
      command, 
      { 
        "first_param" => ["foo"],
        "second_param" => ["foo", "bar", "baz"]
      }
    )
    assert_not_nil request
    assert_equal "foo", request.get_param_value("first_param")
    assert_equal ["foo", "bar", "baz"], request.get_param_value("second_param")
  end
  
  def test_has_param_value
    command = RHCP::Command.new("test", "a test", nil)
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    command.add_param(RHCP::CommandParam.new("second_param", "this is the second param", { :allows_multiple_values => true }))
    request = RHCP::Request.new(
      command, 
      { 
        "first_param" => ["foo"],
        "second_param" => ["foo", "bar", "baz"]
      }
    )
    assert request.has_param_value("first_param")
    assert ! request.has_param_value("third_param")
  end
  
  def test_partial_request
    command = RHCP::Command.new("test", "another test", lambda {})
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param", { :mandatory => true }))
    partial_request = RHCP::Request.new(command, {})
    assert_not_nil partial_request
  end
  
  def test_json
    command = RHCP::Command.new("request_test", "a test", nil)
    command.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    command.add_param(RHCP::CommandParam.new("second_param", "this is the second param", { :allows_multiple_values => true }))
    broker = RHCP::Broker.new()
    broker.register_command(command)
    r= RHCP::Request.new(
      command,
      { 
        "first_param" => ["foo"],
        "second_param" => ["foo", "bar", "baz"]
      },
      RHCP::Context.new({
        "juliet" => "naked"
      })
    )
    json = r.to_json
    puts "request as JSON : >>#{json}<<"
    assert_not_nil json
    r2 = RHCP::Request.reconstruct_from_json(broker, json)
    assert_instance_of RHCP::Request, r2
    assert_equal r.command, r2.command
    assert_equal r.param_values, r2.param_values
    assert_equal r.context.cookies, r2.context.cookies
  end
  
  def test_execute
    command = RHCP::Command.new("request_test", "a test", lambda { |req,res| "jehova" })    
    r= RHCP::Request.new(
      command
    )
    res = r.execute
    assert_not_nil res
    assert_equal "jehova", res.data
  end
  
  def test_execute_with_params
    command = RHCP::Command.new("request_test", "a test", lambda { |req,res| "***" + req.get_param_value("first_one") + "***" }
    ).add_param(RHCP::CommandParam.new("first_one", "pole position"))
    r= RHCP::Request.new(
      command,
      {
        "first_one" => "lucky bastard"
      }
    )
    res = r.execute()
    assert_not_nil res
    assert_equal "***lucky bastard***", res.data
  end

  def test_request_with_context
    command = RHCP::Command.new("gimme_context", "you provide the food, i provide the context", lambda { |req,res| req.get_param_value("the_host") })
    command.add_param(RHCP::CommandParam.new("the_host", "the value that will be filled throught the context", {
      :mandatory => true,
      :autofill_context_key => 'host'
    }))
    command.add_param(RHCP::CommandParam.new("second_param", "second param", {
      :mandatory => true
    }))

    r= RHCP::Request.new(
      command,
      {
        "the_host" => "deepthought",
        "second_param" => "bla"
      }
    )
    res = r.execute()
    assert_not_nil res
    assert_equal "deepthought", res.data

    
    r= RHCP::Request.new(
      command, 
      {"second_param" => "bla"},
      RHCP::Context.new({'host' => "endeavour"})
    )
    res = r.execute()
    assert_not_nil res
    assert_equal "endeavour", res.data
  end

  # if a parameter is specified both in the context and in the parameter values,
  # the parameter values shall rule
  def test_param_values_context_precedence
    command = RHCP::Command.new("gimme_context", "you provide the food, i provide the context", lambda { |req,res| req.get_param_value("the_host") })
    command.add_param(RHCP::CommandParam.new("the_host", "the value that will be filled throught the context", {
      :mandatory => true,
      :autofill_context_key => 'host'
    }))
    command.add_param(RHCP::CommandParam.new("second_param", "second param", {
      :mandatory => true
    }))

    r= RHCP::Request.new(
      command,
      {"second_param" => "bla", "the_host" => "deepthought"},
      RHCP::Context.new({'host' => "endeavour"})
    )
    res = r.execute()
    assert_not_nil res
    assert_equal "deepthought", res.data
  end
  
end
