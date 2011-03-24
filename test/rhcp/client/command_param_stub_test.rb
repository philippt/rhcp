$:.unshift File.join(File.dirname(__FILE__),'..','..', '..', 'lib')

require 'test/unit'
require 'rhcp/test_base'
require 'rhcp/client/command_param_stub'
require 'rhcp'
require 'rhcp/command_param'

class CommandParamStubTest < TestBase

  def param_lookup
    ["foo", "bar", "baz"]
  end
  
  def setup
    @p = RHCP::CommandParam.new("test", "this param is used for testing purposes only",
      :mandatory => true,
      :allows_multiple_values => true,
      :lookup_method => self.method(:param_lookup),
      :is_default_param => true,
      :autofill_context_key => 'zaphod'
    )    
  end
  
  def test_json
    json = @p.to_json
    puts "json : >>#{json}<<"
    p2 = RHCP::Client::CommandParamStub.reconstruct_from_json(json)
    assert_not_nil p2
    assert_instance_of RHCP::Client::CommandParamStub, p2
    assert_equal @p.name, p2.name
    assert_equal @p.description, p2.description
    assert_equal @p.allows_multiple_values, p2.allows_multiple_values
    assert_equal @p.has_lookup_values, p2.has_lookup_values
    assert_equal @p.is_default_param, p2.is_default_param
    assert_equal @p.mandatory, p2.mandatory
    assert_equal @p.autofill_context_key, p2.autofill_context_key
    
    json_hash = JSON.parse(json)
    p3 = RHCP::Client::CommandParamStub.reconstruct_from_json(json_hash)
    assert_instance_of RHCP::Client::CommandParamStub, p3
    assert_equal @p.name, p3.name
    assert_equal @p.description, p3.description
    assert_equal @p.allows_multiple_values, p3.allows_multiple_values
  end
  
  # when a param is "stubbed", it should be possible to inject a method
  # for retrieving the lookup values
  def test_stubbing
    json = @p.to_json
    stub = RHCP::Client::CommandParamStub.reconstruct_from_json(json)
    stub.get_lookup_values_block = lambda {
      |partial_value|
      [ "mascarpone", "limoncello" ]
    }
    command = RHCP::Command.new("test", "a command for testing", lambda { |request,response|
      first_param = request.get_param_value("first_param")
      puts "just testing : #{first_param}"
      first_param.reverse
    })
    request = RHCP::Request.new(command, {})
    lookup_values = stub.get_lookup_values(request)
    assert_equal [ "mascarpone", "limoncello" ], lookup_values
  end
  
  def test_stubbing_without_lookup_values
    p = RHCP::CommandParam.new("test", "without lookup values",
      :mandatory => true,
      :allows_multiple_values => true,
      :is_default_param => true
    )
    stub = RHCP::Client::CommandParamStub.reconstruct_from_json(p.to_json())
    has_been_invoked = false
    stub.get_lookup_values_block = lambda {
      |partial_value|
      has_been_invoked = true
    }
    stub.get_lookup_values(nil, nil)
    assert_equal false, has_been_invoked
  end
  
  
end
