require 'rhcp/broker'
require 'memcache'

module RHCP

  class MemcachedBroker < Broker

    def initialize(wrapped_broker, memcached_server = "127.0.0.1:11211", expiration_seconds = 3600)
      super()
      @wrapped_broker = wrapped_broker
      
      @cache = MemCache.new(
        [memcached_server]
      )
      @expiry_seconds = expiration_seconds
    end

    # TODO would be nice if we could turn the caching on and off through commands
    
    def get_command_list(context = RHCP::Context.new())
      @wrapped_broker.get_command_list(context)
    end

    def register_command(command)
      @wrapped_broker.register_command(command)
    end

    def clear
      @wrapped_broker.clear()
    end
    
    def get_lookup_values(request, param_name)
      sorted_param_values = []
      request.param_values.keys.sort.each do |key|
        sorted_param_values << request.param_values[key]
      end
      cache_key = 'lookup_' + request.command.name + '_' + sorted_param_values.join('|')

      result = nil
      if ((request.context == nil) or (not request.context.cookies.has_key?('__caching.disable')))
        result = @cache.get(cache_key)
      end
      
      if result == nil then
        result = @wrapped_broker.get_lookup_values(request, param_name)
        @cache.add(cache_key, result, @expiry_seconds)
      end

      result
    end
    
    def execute(request)
      command = get_command(request.command.name, request.context)
  
      result = nil
  
      # construct the cache key out of the command name and all parameter values
      sorted_param_values = []
      request.param_values.keys.sort.each do |key|
        sorted_param_values << request.param_values[key]
      end
      cache_key = request.command.name + '_' + sorted_param_values.join('|')
  
      should_read_from_cache = 
        (command.is_read_only) &&
        ( (not command.result_hints.has_key?(:cache)) || (command.result_hints[:cache]) ) &&
        ((request.context == nil) or (not request.context.cookies.has_key?('__caching.disable')))
  
      if should_read_from_cache
        cached_response_json = @cache.get(cache_key)
        if cached_response_json
          #cached_response = JSON.parse(cached_response_json)
          cached_response = RHCP::Response.reconstruct_from_json(cached_response_json)
          $logger.debug("got data from cache for #{cache_key}")
          cached_data = cached_response.data
          
          # TODO why don't we just throw back the response?
          response = RHCP::Response.new()          
          response.data = cached_data
          response.status = RHCP::Response::Status::OK
          
          # all context that has been sent with the request should be sent back
          response.context = request.context.cookies
          
          # also, we want to add all context that has been returned by the cached response
          if cached_response.context != nil then
            if response.context == nil then
              response.context = {}
            end
            $logger.debug("merging in context from cached response : #{cached_response.context}")
            cached_response.context.each do |k,v|
              response.context[k] = v
            end
          end
          
          response.created_at = cached_response.created_at 
          
          result = cached_data
        else
  
        end
      end
  
      if result == nil
        response = @wrapped_broker.execute(request)
  
        # TODO we might want to store the result in memcached nevertheless
        if should_read_from_cache
          # TODO do we want to cache failed command executions as well?
          $logger.debug("storing data in cache for : #{cache_key}")
          @cache.add(cache_key, response.to_json, @expiry_seconds)
        end
      end
  
      response
    end
  
  end
    
end    