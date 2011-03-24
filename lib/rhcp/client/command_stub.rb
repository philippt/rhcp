require 'rhcp/command'
require 'rhcp/client/command_param_stub'
require 'rubygems'
require 'json'


module RHCP
  
  module Client
    
      # This is a stub that represents a remote RHCP::Command.
      # Instances of this class will live in a client that uses one of the brokers
      # from the RHCP::Client package. The interesting aspect about this stub is
      # that the execute method is modified so that it does not execute the
      # command directly, but can be modified from outside (by setting the
      # +execute_block+ property) so that broker classes can inject their
      # remote invocation logic.
      class CommandStub < RHCP::Command
        
        attr_accessor :execute_block
        
        # constructs a new instance
        # should not be invoked directly, but is called from +reconstruct_from_json+
        def initialize(name, description)
          super(name, description, lambda {})
        end
        
        # builds a CommandStub out of some json data (either serialized as string
        # or already unpacked into a ruby-hash)
        # all nested params are unmarshalled as RHCP::CommandParamStub instances
        # so that we are able to inject the logic for invoking get_lookup_values
        # remotely
        def self.reconstruct_from_json(json_data)
          object = json_data.instance_of?(Hash) ? json_data : JSON.parse(json_data)
          args = object.values_at('name', 'description')
          instance = self.new(*args)
          if object.values_at('read_only')
            instance.mark_as_read_only
          end
          instance.result_hints = {
            :display_type => object['result_hints']['display_type'],
            :overview_columns => object['result_hints']['overview_columns'],
            :column_titles => object['result_hints']['column_titles']
          }
          object['params'].each do |p|
            param = RHCP::Client::CommandParamStub.reconstruct_from_json(p)
            instance.add_param(param)
          end
          instance
        end        
        
        # we don't want to execute the command block as the normal RHCP::Command
        # does, but rather want to call the block injected by the registry that
        # has created this stub.
        def execute_request(request)
          @execute_block.call(request)
        end
      end      
      
    end
    
end


