$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp/response'

class ResponseTest < Test::Unit::TestCase
  
  def test_simple
    response = RHCP::Response.new()
    assert_not_nil response
    response.mark_as_error("something went wrong")
    assert_equal "something went wrong", response.error_text
    assert_equal "", response.error_detail    
  end
  
  def test_payload
    response = RHCP::Response.new()
    assert_not_nil response
    response.set_payload("some data")
    assert_equal "some data", response.data
  end
  
  def test_json
    response = RHCP::Response.new()    
    response.set_payload("some data")
    response.mark_as_error("something went wrong", "things got really fucked up")
    
    json = response.to_json()
    assert_not_nil json
    r2 = RHCP::Response.reconstruct_from_json(json)
    #r2 = JSON.parse(json)
    assert_not_nil r2
    assert_instance_of RHCP::Response, r2
    assert_equal RHCP::Response::Status::ERROR, r2.status
    assert_equal "something went wrong", r2.error_text
    assert_equal "things got really fucked up", r2.error_detail
    assert_equal "some data", r2.data
  end

  def test_with_context
    response = RHCP::Response.new()
    response.set_payload("some data")
    response.set_context({'cookies' => 'good'})
    assert_equal 'good', response.context['cookies']
  end

  def test_json_with_context
    response = RHCP::Response.new()
    response.set_payload("some data")
    response.set_context({'cookies' => 'good'})
    r2 = RHCP::Response.reconstruct_from_json(response.to_json())
    assert_equal response.context, r2.context
  end
  
end
