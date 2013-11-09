require 'rhcp/broker'

module RHCP

  class LoggingBroker < Broker

    def initialize(wrapped_broker)
      super()
      @wrapped_broker = wrapped_broker
      @logger = RHCP::ModuleHelper::instance.logger
      @blacklisted_commands = [ ]
    end

    def get_command_list(context = RHCP::Context.new())
      @wrapped_broker.get_command_list(context)
    end

    def register_command(command)
      @wrapped_broker.register_command(command)
    end

    def clear
      @wrapped_broker.clear()
    end
    
    def blacklist_defaults
      [ ]
    end
    
    def get_blacklisted_commands
      []
    end
    
    def get_graylisted_commands
      []
    end
    
    def graylist
      [ "on_machine", "list_machines" ]
    end
    
    def blacklist
      blacklist_defaults + get_blacklisted_commands
    end
    
    # TODO would be nice if this helper method would be accessible from inside vop plugins
    def var_name(name)
      self.class.to_s + "." + name
    end
    
    def execute(request) 
      command = get_command(request.command.name, request.context)
      mode = command.is_read_only ? 'r/o' : 'r/w'

      should_be_logged = (! blacklist.include?(command.name) && ! command.is_read_only)

      #puts "#{command.name} [#{mode}] #{should_be_logged ? 'pass' : 'skip'}"

      if should_be_logged
        request_id = Thread.current[var_name("request_id")]
        
        is_new_request = request_id == nil
        
        if is_new_request
          if mode == 'r/o'
            should_be_logged = false
          else
            new_request_id = if request.param_values.has_key?('request_id')
              request.param_values['request_id'].first
            elsif request.context.request_context_id != nil
              request.context.request_context_id
            else
              Time.now().to_i.to_s + '_' + request.command.name
            end
              
            Thread.current[var_name("request_id")] = new_request_id
            
            Thread.current[var_name("stack")] = []
            Thread.current[var_name("id_stack")] = []
          end
        end
        
        if should_be_logged
          Thread.current[var_name("stack")] << command.name #unless graylist.include? command.name
          
          level = Thread.current[var_name("stack")].size()
          
          start_ts = Time.now()
          log_request_start(Thread.current[var_name("request_id")], level, mode, stack_for_display, request, start_ts)
        end
      end
      
      response = @wrapped_broker.execute(request)
      
      if should_be_logged
        stop_ts = Time.now()
        duration = stop_ts.to_i - start_ts.to_i
        
        log_request_stop(Thread.current[var_name("request_id")], level, mode, stack_for_display, request, response, duration)
        
        Thread.current[var_name("stack")].pop
        if level == 1
          Thread.current[var_name("request_id")] = nil
        end
      end
      
      response
    end
    
    def stack_for_display
      Thread.current[var_name("stack")].select do |command_name|
        not graylist.include? command_name
      end.join(".")
    end

    def log_request_start(request_id, level, mode, current_stack, request, start_ts)
      $logger.debug("> #{request_id} #{level} [#{mode}] #{current_stack.join('.')} #{request}")
    end
    
    def log_request_stop(request_id, level, mode, current_stack, request, response, duration)
      $logger.debug("< #{request_id} #{level} [#{mode}] #{current_stack.join('.')} #{request}")
    end

  end

end