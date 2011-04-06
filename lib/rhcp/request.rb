require 'rhcp/rhcp_exception'
require 'rhcp/broker'

require 'rubygems'
require 'json'

module RHCP

  # This class represents a request initiated by a RHCP client to a RHCP server.
  # It is passed as an argument to the method that should execute the requested
  # command
  class Request

    attr_reader :command
    attr_reader :param_values
    attr_reader :context

    # default constructor; will throw exceptions on invalid values
    def initialize(command, some_param_values = {}, context = RHCP::Context.new())
      param_values = some_param_values.clone()
      @logger = RHCP::ModuleHelper.instance().logger
      @logger.debug "initializing request #{command.name} with params #{param_values}"
      raise RHCP::RhcpException.new("command may not be null") if command == nil

      @context = context

      command.params.each do |param|
        value_from_context = param.find_value_in_context(context)
        if value_from_context != nil          
          # if the parameter has been specified in the param values, do not override
          if ! param_values.has_key?(param.name)
            @logger.debug "pre-filling param #{param.name} with value '#{value_from_context}' (context key '#{param.autofill_context_key}')"
            param_values[param.name] = value_from_context
          end
        end
      end

      # autobox the parameters if necessary
      param_values.each do |k,v|
        if ! v.instance_of?(Array)
          param_values[k] = [ v ]
        end
      end

      @command = command
      @param_values = param_values

      printable_param_values = param_values.map do |a,b|
        a + '=' + b.join(',')
      end.join('; ')
      @logger.debug("request initialized : command '#{command.name}', params : #{printable_param_values}")
    end

    # used to retrieve the value for the specified parameter
    # returns either the value or an array of values if the parameter allows
    # multiple values
    def get_param_value(param_name)
      raise "no such parameter : #{param_name}" unless @param_values.has_key?(param_name)
      param = @command.get_param(param_name)
      if (param.allows_multiple_values)
        @param_values[param_name]
      else
        @param_values[param_name][0]
      end
    end

    def has_param_value(param_name)
      @param_values.has_key?(param_name)
    end

    # convenience method that executes the command that actually delegates to the
    # command that's inside this request
    def execute
      @command.execute_request(self)
    end

    # reconstructs the request from it's JSON representation
    # Since the JSON version of a request does hold the command name instead
    # of the full command only, a broker is needed to lookup the command by
    # it's name
    #
    # Params:
    #   +broker+ is the broker to use for command lookup
    #   +json_data+ is the JSON data that represents the request
    def self.reconstruct_from_json(broker, json_data)
      object = JSON.parse(json_data)
      
      context = object.has_key?('context') ?
        RHCP::Context.reconstruct_from_json(object['context']) :
        RHCP::Context.new(object['cookies'])
        
      command = broker.get_command(object['command_name'], context)      
        
      self.new(command, object['param_values'], context)
    end

    # returns a JSON representation of this request.
    def to_json(*args)
      {
        'command_name' => @command.name,
        'param_values' => @param_values,
        'context' => @context.to_json
      }.to_json(*args)
    end

    def to_s
      "#{@command.name} (#{@param_values})"
    end

  end

end