module RHCP

  require 'rubygems'
  require 'json'
  
  require 'rhcp/response'
  
  # This class represents a single RHCP command, i.e. a functionality that
  # should be exposed to clients.
  class Command
      
    # TODO add metadata about the command's result (display type ("table"), column order etc.)
    
    # a qualified name that identifies this command in a dot-separated namespace
    attr_reader :full_name
    
    # a unique name for this command
    attr_reader :name

    # textual description of what this command is doing
    attr_accessor :description
    
    # the parameters supported by this command
    attr_reader :params

    # the block that should be executed if this command is invoked
    attr_accessor :block
    
    # the parameter that is the default param for this command; might be nil
    attr_reader :default_param
    
    # "true" if this command returns data, but does not modify anything.
    attr_reader :is_read_only

    attr_reader :accepts_extra_params
    
    attr_reader :ignores_extra_params
    
    attr_accessor :notifications
    
    # an array of context keys that enable this command
    # 
    # if at least one of the listed keys is found in the context, the command
    # is enabled, otherwise not. if no keys are listed, the command is enabled
    # by default
    attr_accessor :enabled_through_context_keys
    
    attr_accessor :available_if
    
    # hints about how the result of this command might be displayed
    attr_accessor :result_hints

    def initialize(name, description, block = nil)
      @logger = RHCP::ModuleHelper.instance().logger
      
      #@logger.info("full name : #{name}")
      @full_name = name
      @name = name.split(".").last
      
      @description = description
      @block = block unless block == nil
      @params = Array.new()
      
      @default_param = nil
      @is_read_only = false
      @enabled_through_context_keys = nil
      
      @accepts_extra_params = false
      @ignores_extra_params = false
      
      @notifications = false
      
      @available_if = nil
      
      # TODO formalize this! (we need rules how clients should react, otherwise this will be a mess)
      # TODO in some cases, the display_type could also be guessed from the response, I guess
      @result_hints = {
        :display_type => "unspecified",
        :overview_columns => [],
        :column_titles => []
      }
    end

    def is_enabled?(context = RHCP::Context.new(), param_values = nil)
      result = true

      if @enabled_through_context_keys != nil
        result = false
        @enabled_through_context_keys.each do |key|
          if context.cookies.keys.select { |element| element == key }.size() > 0
            @logger.debug "enabling command #{@name} because of context key #{key}"
            result = true
            break
          end
        end
      end

      if param_values != nil        
        if @available_if != nil
          result = @available_if.call(param_values)
        end
      end

      result
    end

    # adds a new parameter and returns the command
    def add_param(new_param)
      existing_params = @params.select do |param|
        param.name == new_param.name
      end
      raise "duplicate parameter name '#{new_param.name}'" if existing_params.size > 0
      @params << new_param
      if new_param.is_default_param
        if @default_param != nil
          raise RHCP::RhcpException.new("there can be only one default parameter per command, and the parameter '#{@default_param.name}' has already been marked as default")
        end
        @default_param = new_param
      end
      self
    end
    
    # marks this command as a read-only command, i.e. a command that returns data,
    # but does not perform any action.
    # this information might influence permissions and/or the way the command's
    # result is displayed
    def mark_as_read_only()
      @is_read_only = true
      self
    end
    
    def accept_extra_params()
      @accepts_extra_params = true
      self
    end
    
    def ignore_extra_params()
      @ignores_extra_params = true
      self
    end

    # returns the specified CommandParam
    # or throws an RhcpException if the parameter does not exist
    def get_param(param_name)
      existing_params = @params.select do |param|
        param.name == param_name
      end
      
      # there shouldn't be none
      raise RHCP::RhcpException.new("undefined parameter '#{param_name}' in '#{self.name}'") unless existing_params.size > 0
      
      # there can be only one
      raise RHCP::RhcpException.new("BUG: duplicate parameters found") if existing_params.size > 1
      
      existing_params.first
    end

    # returns an array of all mandatory params for this command
    # mandatory parameters that are auto-filled through the context are
    # filtered out
    def get_mandatory_params(context = RHCP::Context.new())
      @params.select do |param| 
        param.mandatory &&
        ! param.find_value_in_context(context)
      end
    end

    # invokes this command
    def execute_request(request)
      @logger.debug "gonna execute request >>#{request}<<"
      
      response = RHCP::Response.new()
      
      # check all param values for plausibility
      begin
        request.param_values.each do |key,value|
          get_param(key).check_param_is_valid(request, value)
        end
      rescue Exception => ex
        raise unless /undefined\sparameter/.match(ex.message)
      end

      # check that we've got all mandatory params
      @params.each do |param|
        if param.mandatory && ! request.param_values.has_key?(param.name)
          raise RHCP::RhcpException.new("missing mandatory parameter '#{param.name}' for command '#{self.name}'")
        end
      end
      
      begin
        # TODO redirect the block's output (both Logger and STDOUT/STDERR) and send it back with the response?
        result = block.call(request, response)
        response.set_payload(result)
      rescue Exception => ex
        response.mark_as_error(ex.to_s, ex.backtrace.join("\n"))
      end

      response
    end
    
    def execute(param_values = {}, context = RHCP::Context.new())
      req = RHCP::Request.new(self, param_values, context)
      execute_request(req)
    end
    
    def execute_from_ruby_args(args, additional_params, block)
      # args is an array - but we need the (optional) hash on index 0
      param_values = {}
      if args.length > 0
        param_values = args.first
        if param_values.class == String && default_param != nil
          $logger.debug "autoboxing for #{default_param.name}"
          param_values = {
            default_param.name => param_values
          }
        end
      end
      if defined?(block) and self.params.select { |p| p.name == "block" }.size > 0
        param_values["block"] = block
      end

      # we need to carry along the context
      the_broker = Thread.current['broker']
      
      c = the_broker.context.clone
      c.cookies.merge! additional_params
      param_values.merge! additional_params 

      request = RHCP::Request.new(self, param_values, c)
      response = the_broker.execute(request)

      if (response.status != RHCP::Response::Status::OK) then        
        #$logger.error("#{response.error_text}\n#{response.error_detail}")
        e = RhcpException.new(response.error_text)
        e.set_backtrace(response.error_detail)
        raise e
      end
      response.data
    end
    
    def add_as_instance_method(the_instance, additional_params = {})
      rhcp_command = self
      command_name = rhcp_command.name
  
      already_defined = the_instance.methods.select { |m| m == command_name }.size() > 0
      if already_defined
        the_instance.class.send(:remove_method, command_name.to_sym)
      end
      the_instance.class.send(:define_method, command_name.to_sym) do |*args|
        execute_from_ruby_args(args, additional_params)
      end
    end
    
    
    # we do not serialize the block (no sense in this) nor the default param
    # when the command is unmarshalled as stub, the default param will be set again
    # automatically by add_param(), and the block will be replaced by the block
    # that does the remote invocation
    def to_json(*args)
      {
        'name' => @name,
        'description' => @description,
        'params' => @params,
        'read_only' => @is_read_only,
        'result_hints' => @result_hints,
        'enabled_through_context_keys' => @enabled_through_context_keys
      }.to_json(*args)
    end
    
  end

end