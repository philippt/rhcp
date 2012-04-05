$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test/unit'
require 'logger'
require 'mocha'

$logger = Logger.new(STDOUT)

class TestBase < Test::Unit::TestCase

  def test_fine
    $logger.debug "There's absolutely no cause for alarm."
  end

  def read_file(filename)
    file_name = File.dirname(__FILE__) + '/data/' + filename
    File.new(file_name).read
  end

  def read_yaml(filename)
    file_name = File.dirname(__FILE__) + '/data/' + filename
    YAML::load(File.open(file_name))
  end

end