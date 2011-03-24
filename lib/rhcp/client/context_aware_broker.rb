module RHCP

  module Client

    # a broker decorator that keeps track of the current context
    class ContextAwareBroker

      attr_accessor :context

      def initialize(wrapped_broker)
        @wrapped_broker = wrapped_broker
        @context = RHCP::Context.new()
      end

      def register_command(command)
        @wrapped_broker.register_command command
      end

      def clear
        @wrapped_broker.clear()
      end

      def get_command_list(context=@context)
        @wrapped_broker.get_command_list(context)
      end

      def give_the_request_some_context_rico(request)
        # TODO think about the errors of your ways, son...
        @context.cookies.each do |k,v|
          request.context.cookies[k] = v
        end
        new_request = RHCP::Request.new(request.command, request.param_values, request.context)
        $logger.debug("+++ wrapped own request  : #{new_request}")
        new_request
      end

      def execute(request)
      #def execute(command_name, params = {}, context=@context)
        $logger.debug("+++ ContextAwareBroker.execute (#{request.command.name}, #{request.param_values}, #{request.context}) +++")

        new_request = give_the_request_some_context_rico(request)
        #command = get_command(new_request.command.name, new_request.context)
        response = @wrapped_broker.execute(new_request)

        # store context received with response
        if response.context != nil
          # TODO it would be nice if we could delete cookies as well
          response.context.each do |key,value|
            @context.cookies[key] = value
            $logger.debug "storing value '#{value}' for key '#{key}' in context"
          end
        end

        response
      end

      def get_command(command_name, context=@context)
        @wrapped_broker.get_command(command_name, context)
      end

      def get_mandatory_params(command_name, context=@context)
        command = get_command(command_name)
        command.get_mandatory_params(context)
      end

      def get_lookup_values(request, param_name)
        request_with_context = give_the_request_some_context_rico(request)
        @wrapped_broker.get_lookup_values(request_with_context, param_name)
      end

      def check_param_is_valid(request, param_name, possible_value)
        request_with_context = give_the_request_some_context_rico(request)
        @wrapped_broker.check_param_is_valid(request_with_context, param_name, possible_value)
      end

    end

  end

end
