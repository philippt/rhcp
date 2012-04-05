$:.unshift File.join(File.dirname(__FILE__),'..','..','..','lib')

require 'rubygems'
require 'json'

require 'test/unit'
require 'rhcp'
require 'rhcp'
require 'rhcp'

class CommandStubTest < Test::Unit::TestCase
  
  def command_method(request, response)
    first_param = request.get_param_value("first_param")
    puts "just testing : #{first_param}"    
    first_param.reverse
  end
  
  def test_json
    c = RHCP::Command.new("test", "a command for testing", self.method(:command_method))
    c.add_param(RHCP::CommandParam.new("first_param", "this is the first param"))
    c.result_hints[:display_type] = "table"
    json = c.to_json
    puts "JSON : >>#{JSON.pretty_generate(c)}<<"
    assert_not_nil json
    c2 = RHCP::Client::CommandStub.reconstruct_from_json(json)
    assert_not_nil c2
    assert_instance_of RHCP::Client::CommandStub, c2
    assert_equal c.name, c2.name
    assert_equal c.description, c2.description
    assert_equal c.params.size, c2.params.size
    assert_equal c.result_hints, c2.result_hints
    
    json_hash = JSON.parse(json)
    c3 = RHCP::Client::CommandStub.reconstruct_from_json(json_hash)
    assert_instance_of RHCP::Client::CommandStub, c3
    assert_equal c.name, c3.name
    assert_equal c.description, c3.description
    assert_equal c.params.size, c3.params.size
  end
  
  def test_json_without_result_hints
    c = RHCP::Command.new("test", "no hints this time", lambda {})
    json = c.to_json
    puts "JSON : >>#{JSON.pretty_generate(c)}<<"
    assert_not_nil json
    c2 = RHCP::Client::CommandStub.reconstruct_from_json(json)
    assert_not_nil c2
    assert_instance_of RHCP::Client::CommandStub, c2
    assert_equal c.name, c2.name
    assert_equal c.description, c2.description
    assert_equal c.params.size, c2.params.size
    assert_equal c.result_hints, c2.result_hints
  end
  
end
