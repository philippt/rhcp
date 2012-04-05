$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp/command_param'

class CommandParamTest < Test::Unit::TestCase
  
  def param_lookup
    ["foo", "bar", "baz"]
  end
  
  def test_creation
    param = RHCP::CommandParam.new("test", "this param is used for testing purposes only")
    assert_not_nil param, "a param should not be nil after creation"
    assert_equal false, param.mandatory, "by default, params should not be mandatory"
    assert_equal false, param.has_lookup_values, "by default, a param does not have lookup values"
    assert_equal false, param.allows_multiple_values, "by default, a param should not allow multiple values"
    assert_equal false, param.is_default_param
  end
  
  def test_options
    param = RHCP::CommandParam.new("test", "this param is used for testing purposes only",
      :mandatory => true,
      :allows_multiple_values => true,
      :lookup_method => self.method(:param_lookup),
      :is_default_param => true
    )
    assert_not_nil param, "a param should not be nil after creation"
    assert_equal true, param.mandatory
    assert_equal true, param.allows_multiple_values
    assert_equal true, param.has_lookup_values
    assert_equal true, param.is_default_param
  end
  
#  def test_lookup_values
#    param = RHCP::CommandParam.new("lookup_test", "testing if lookup values are working",
#      :lookup_method => self.method(:param_lookup)
#    )
#    assert_not_nil param
#    assert_equal param_lookup(), param.get_lookup_values(nil, nil)
#  end
#  
#  def test_partial_lookup_values
#    param = RHCP::CommandParam.new("lookup_test", "testing if partial lookup values are working",
#      :lookup_method => self.method(:param_lookup)
#    )
#    assert_not_nil param
#    assert_equal ["bar", "baz"], param.get_lookup_values("ba")
#  end
  
#  def test_get_lookup_values_without_lookup
#    param = RHCP::CommandParam.new("lookup_test", "testing if partial lookup values are working")
#    assert_not_nil param
#    assert_equal [], param.get_lookup_values()
#  end
  
end
