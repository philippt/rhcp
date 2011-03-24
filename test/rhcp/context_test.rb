$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'

require 'rhcp'
require 'rhcp/context'

class ContextTest < Test::Unit::TestCase

  def test_the_context
    context = RHCP::Context.new({'nice' => 'sun'})
    p context
    puts context.to_s
  end

end
