$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'rhcp'

require 'test/unit'
require 'rhcp/tests_for_brokers'

class HttpBrokerTest < Test::Unit::TestCase

  include TestsForBrokers

  def self.suite
    @@broker = RHCP::Broker.new()

    @@exporter = RHCP::HttpExporter.new(@@broker, :port => 42001)
    @@exporter.start()
    super
  end

  def setup
    RHCP::ModuleHelper.instance.logger.level = Logger::DEBUG
    $logger.level = Logger::DEBUG
    @broker = @@broker
    @broker.clear
    url = URI.parse("http://localhost:42001")
    @test_broker = RHCP::Client::HttpBroker.new(url)
    #@test_broker = RHCP::Client::ContextAwareBroker.new(broker)
  end

  # TODO test with a real second VM

end
