require 'rubygems'
require 'json'

require 'rhcp/rhcp_exception'

module RHCP

  # This class represents a single parameter that can be specified for
  # a certain command. It is used by the server side to define which
  # commands are available for clients.
  class CommandParam

    # a unique name for this parameter
    attr_reader :name
    # a textual description of this parameter's meaning
    attr_reader :description
    # "true" if the command can not be invoked without this parameter
    attr_reader :mandatory
    # "true" if there are lookup values available for this parameter
    attr_reader :has_lookup_values
    # "true" if this parameter might be specified multiple times, resulting
    # in a list of values for this parameter
    attr_reader :allows_multiple_values    
    # "true" if this parameter is the default parameter for the enclosing command
    attr_reader :is_default_param
    # the key to a context value that is used for filling this parameter
    attr_reader :autofill_context_key
    
    attr_accessor :allows_extra_values
    
    attr_accessor :default_value

    # creates a new command parameter
    # options is a hash, possibly holding the following values (all optional)
    #   :mandatory                true if the parameter is necessary for this command
    #   :allows_multiple_values   true if this parameter might be specified multiple times
    #   :lookup_method            a block that returns an array of lookup values valid for this param
    #   :is_default_param         true if this parameter is the default param for the enclosing command
    #   :default_value            a value to use as default (who would have thought?)
    def initialize(name, description, options = {})
      @name = name
      @description = description

      # TODO also, it should be possible to allow extra values for params with lookups
      @mandatory = options[:mandatory] || false
      @lookup_value_block = options[:lookup_method]     
      @has_lookup_values = @lookup_value_block != nil
      @allows_multiple_values = options[:allows_multiple_values] || false
      @is_default_param = options[:is_default_param] || options[:default_param] || false
      @autofill_context_key = options[:autofill_context_key] || nil
      @default_value = options[:default_value] || nil
      @allows_extra_values = options[:allows_extra_values] || false
    end

    # searches the context for a values that can be auto-filled
    # if a value is found in the context, it is returned
    # if this parameter cannot be filled from the context, nil is returned
    def find_value_in_context(context)
      result = nil
      if @autofill_context_key != nil
        if context.cookies.has_key?(@autofill_context_key)
          result = context.cookies[@autofill_context_key]
        end
      end
      result
    end

    # returns lookup values for this parameter
    # if "partial_value" is specified, only those values are returned that start
    # with "partial_value"    
    def get_lookup_values(request, partial_value = "")
      if @has_lookup_values
        # TODO mix other_params and context
        $logger.debug "get_lookup_values for '#{request.command.name}'; request : #{request}"
        values = []
        if @lookup_value_block.arity == 1 or @lookup_value_block.arity == -1
          values = @lookup_value_block.call(request)
        else
          values = @lookup_value_block.call()
        end
        
        values.grep(/^#{partial_value}/)
      else
        []
      end
    end

    # throws an exception if +possible_value+ is not a valid value for this parameter
    # returns true otherwise
    # note that this methods expects +possible_value+ to be an array since all param values
    # are specified as arrays
    def check_param_is_valid(request, possible_value)

      # formal check : single-value params against multi-value params
      if ((! @allows_multiple_values) && (possible_value.size > 1))
        raise RHCP::RhcpException.new("multiple values specified for single-value parameter '#{@name}'")
      end

      # check against lookup values
      if @has_lookup_values
        possible_value.each do |value|
          if (not get_lookup_values(request).include?(value)) and (not @allows_extra_values)
            raise RHCP::RhcpException.new("invalid value '#{value}' for parameter '#{@name}'")
          end
        end
      end

      true
    end
    
    # we do not serialize the lookup_method (it couldn't be invoked remotely
    # anyway)
    def to_json(*args)
      {
        'name' => @name,
        'description' => @description,
        'allows_multiple_values' => @allows_multiple_values,
        'has_lookup_values' => @has_lookup_values,
        'is_default_param' => @is_default_param,
        'mandatory' => @mandatory,
        'autofill_context_key' => @autofill_context_key,
        'allows_extra_values' => @allows_extra_values
      }.to_json(*args)
    end        

  end

end  