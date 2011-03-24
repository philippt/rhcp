require 'rhcp/command_param'

module RHCP
  
  module Client
    
      # This is a proxy representing a remote CommandParam - see
      # RHCP::CommandParam for details
      class CommandParamStub < RHCP::CommandParam
        
        # the block that should be executed when +get_lookup_values+ is called
        # on this CommandParamStub
        attr_accessor :get_lookup_values_block
        
        # when constructing a CommandParamStub, the +:lookup_method+ option is 
        # set to +remote_get_lookup_values+ so that a method can be injected
        # from outside that will retrieve the lookup values (using the
        # +get_lookup_values_block+ property).
        def initialize(name, description, options)
          # we don't need to stub anything if the method does not have lookup values
          if (options[:has_lookup_values])
            options[:lookup_method] = self.method(:remote_get_lookup_values)
          end
          super(name, description, options)
        end
        
        def self.reconstruct_from_json(json_data)
          object = json_data.instance_of?(Hash) ? json_data : JSON.parse(json_data)
          args = object.values_at('name', 'description')
          args << {
            :allows_multiple_values => object['allows_multiple_values'],
            :has_lookup_values => object['has_lookup_values'],
            :is_default_param => object['is_default_param'],
            :mandatory => object['mandatory'],
            :autofill_context_key => object['autofill_context_key']
          }
          self.new(*args)
        end
        
        def remote_get_lookup_values(context = RHCP::Context.new())
          @get_lookup_values_block.call(context)
        end
        
      end      

  end
  
end

 


