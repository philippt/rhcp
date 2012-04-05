require 'rhcp/rhcp_exception'
require 'rhcp/broker'

module RHCP

  class DispatchingBroker < Broker
    def initialize
      @brokers = []
    end
    
    def add_broker(new_broker)
      @brokers << new_broker
      # TODO this is not a good way of handling duplicate detection since the broker has been added to the list already
      get_command_list()
    end

    def get_broker_for_command_name(command_name, context)
      result = nil
      @brokers.each do |broker|
        broker.get_command_list(context).each do |name, command|
          if name == command_name
            result = broker
          end
        end
      end
      raise RHCP::RhcpException.new("no broker found that offers command '#{command_name}'") if result == nil
      result
    end

    # returns a list of all known commands
    def get_command_list(context = RHCP::Context.new())
      result = {}
      @brokers.each do |broker|
        broker.get_command_list(context).each do |name, command|
          raise RHCP::RhcpException.new("duplicate command: '#{name}' has already been defined.") if result.has_key?(name)
          result[name] = command
        end
      end
      result
    end

    def execute(request)
      broker = get_broker_for_command_name(request.command.name, request.context)
      broker.execute(request)
    end

  end
  
end