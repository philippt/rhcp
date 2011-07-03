require 'rhcp/broker'

module RHCP

  class LoggingBroker < Broker

    def initialize(wrapped_broker)
      super()
      @wrapped_broker = wrapped_broker
      @logger = RHCP::ModuleHelper::instance.logger
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
    
    def get_blacklisted_commands
      [ "log_to_jabber", "log_to_jabber_detail", "on_host", "hostname" ]
    end
    
    
    # TODO would be nice if this helper method would be accessible from inside vop plugins
    def var_name(name)
      self.class.to_s + "." + name
    end
    
    def execute(request)
      blacklisted = get_blacklisted_commands.include?(request.command.name)
      if not blacklisted and request.context.cookies.has_key?('__loggingbroker.blacklisted_commands') then
        blacklisted = request.context.cookies['__loggingbroker.blacklisted_commands'].split(',').include?(request.command.name)
      end
  
      command = get_command(request.command.name, request.context)
      mode = command.is_read_only ? 'r/o' : 'r/w'
  
      is_new_request = Thread.current[var_name("request_id")] == nil
      if is_new_request
        Thread.current[var_name("request_id")] = Time.now().to_i.to_s + '_' + request.command.name
        Thread.current[var_name("stack")] = []
        Thread.current[var_name("id_stack")] = []
      end
      
      Thread.current[var_name("stack")] << command.name
      
      level = Thread.current[var_name("stack")].size()
      
      unless blacklisted    
        #$logger.info ">> #{command.name} (#{mode}) : #{Thread.current[var_name("stack")].join(" -> ")}"
        start_ts = Time.now()
        log_request_start(Thread.current[var_name("request_id")], level, mode, Thread.current[var_name("stack")], request, start_ts)
      end
      
      response = @wrapped_broker.execute(request)
      
      unless blacklisted
        stop_ts = Time.now()
        duration = stop_ts.to_i - start_ts.to_i
        
        log_request_stop(Thread.current[var_name("request_id")], level, mode, Thread.current[var_name("stack")], request, response, duration)
      end
      
      Thread.current[var_name("stack")].pop
      
      response
    end

    def log_request_start(request_id, level, mode, current_stack, request, start_ts)
      $logger.debug("> #{request_id} #{level} [#{mode}] #{current_stack.join('.')} #{request}")
    end
    
    def log_request_stop(request_id, level, mode, current_stack, request, response, duration)
      $logger.debug("< #{request_id} #{level} [#{mode}] #{current_stack.join('.')} #{request}")
    end

  end

end