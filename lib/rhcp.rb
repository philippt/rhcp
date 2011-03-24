require 'singleton'
require 'logger'

require 'rhcp/broker'
require 'rhcp/command'
require 'rhcp/command_param'
require 'rhcp/dispatching_broker'
require 'rhcp/http_exporter'
require 'rhcp/request'
require 'rhcp/response'
require 'rhcp/rhcp_exception'
require 'rhcp/client/http_broker'
require 'rhcp/client/context_aware_broker'
require 'rhcp/client/command_stub'
require 'rhcp/client/command_param_stub'
require 'rhcp/logging_broker'

module RHCP #:nodoc:
  
  class Version
    
    include Singleton
    
    MAJOR = 0
    MINOR = 2
    TINY  = 12

    def Version.to_s
      [ MAJOR, MINOR, TINY ].join(".")
    end
    
  end
  
  class ModuleHelper
    
    include Singleton
    
    attr_accessor :logger
    
    def initialize()
      # TODO do we really want to log to STDOUT per default?
      # TODO check the whole package for correct usage of loggers
      @logger = Logger.new(STDOUT)
    end
    
    
  end
  
end

$logger = Logger.new(STDOUT)
