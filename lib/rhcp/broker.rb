require 'rhcp/context'

module RHCP

  # Applications register the commands they are implementing at a broker.
  # The broker holds the list of commands and is the central entry point for
  # all code that wants to export/publish these commands  
  class Broker
    
    attr_reader :name
    
    def initialize(name = "")
      # command_name => command
      @known_commands = Hash.new()
      @name = name
    end  
    
    ################################################################################################
    # public server interface
    
    # registers a new command - this method should be called by the application
    # providing the command
    def register_command(command)
      raise RHCP::RhcpException.new("duplicate command name : #{command.name}") if @known_commands.has_key?(command.name)
      @known_commands[command.name] = command
    end
    
    # removes all commands that have been registered previously
    def clear
      @known_commands = Hash.new()
    end

    ################################################################################################
    # public client interface
    
    # returns a list of all known commands
    def get_command_list(context = RHCP::Context.new())
      result = {}
      @known_commands.each do |name, command|
        if command.is_enabled?(context)
          result[name] = command
        end
      end
      result
    end  
    
    def execute(request)
      command = get_command(request.command.name, request.context)
      command.execute_request(request)
    end
    
    ################################################################################################
    # the following methods are basically helper methods for going through the
    # data returned by get_command_list()
    # 
    # there should be no need to override these in descendant brokers

    # returns the specified command object
    def get_command(command_name, context=RHCP::Context.new())
      commands = get_command_list(context)
      
      raise RHCP::RhcpException.new("no such command : #{command_name}") unless commands.has_key?(command_name)
      commands[command_name]
    end
    
    # returns a list of all mandatory parameters for the specified command
    def get_mandatory_params(command_name, context=RHCP::Context.new())
      command = get_command(command_name, context)
      command.get_mandatory_params(context)
    end
    
    # fetches lookup values for the parameter specified by command_name/param_name
    # might evaluate the values that have already been collected and the current
    # context
    def get_lookup_values(request, param_name)
      command = get_command(request.command.name, request.context)
      command.get_param(param_name).get_lookup_values(request)
    end

    # throws an exception if +possible_value+ is not a valid value for this parameter
    # returns true otherwise
    # note that this methods expects +possible_value+ to be an array since all param values
    # are specified as arrays
    def check_param_is_valid(request, param_name, possible_value)
      command = get_command(request.command.name, request.context)
      param = command.get_param(param_name)
      param.check_param_is_valid(request, possible_value)
    end

  end
end