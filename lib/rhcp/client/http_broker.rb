#require 'rhcp/rhcp'
require 'rhcp/broker'
require 'rhcp/rhcp_exception'
require 'rhcp/client/command_stub'
require 'net/http'
require 'json'

module RHCP
  
  module Client
    
      # This is an implementation of a RHCP broker that retrieves it's data via
      # http from a remote broker. Since it implements the same interface as RHCP::Broker,
      # clients can use it exactly as if they were talking to the broker itself.
      class HttpBroker < Broker

        def initialize(url, user = nil, password = nil)
          # TODO should this really be an URL? or just a host name?
          @url = url
          @logger = RHCP::ModuleHelper.instance.logger
          @logger.debug "connecting to #{@url}"
          
#          req = Net::HTTP::Get.new("/rhcp")
#          if params.has_key?("user") && params.has_key?("password") then
#            req.basic_auth params["user"], params["password"]
#          elsif uri.user != nil then
#            req.basic_auth uri.user, uri.password
#          end      
#          
#          http = Net::HTTP.new(uri.host, uri.port)
#          #http.set_debug_output($stderr)
#          @op.log_to_jabber_detail("message" => "HTTP_START #{uri} : #{req}")
#          response = http.request(req)
          
          http = Net::HTTP.new(@url.host, @url.port)
          request = Net::HTTP::Get.new('/rhcp/')
          request.basic_auth user, password if user and password
          res = http.request request
          
          if (res.code == "200")
            @logger.info "connected to '#{@url}' successfully."
          else
            @logger.error "cannot connect to '#{@url}' : got http status code #{res.code}"
            raise RHCP::RhcpException.new("could not connect to '#{@url}' : got http status code #{res.code} (#{res.message})");
          end
        end

        # returns a list of all known commands
        def get_command_list(context = RHCP::Context.new())          
          # TODO CONTEXT include context
          res = Net::HTTP.new(@url.host, @url.port).start { |http| http.post("/rhcp/get_commands", context.to_json) }   
          if (res.code != "200")
            raise RHCP::RhcpException.new("could not retrieve command list from remote server : http status #{res.code} (#{res.message})")
          end
          
          @logger.debug "raw response : >>#{res.body}<<"

          # the commands are transferred as array => convert into hash
          command_array = JSON.parse(res.body)
          commands = Hash.new()
          command_array.each do |command_string|
            command = RHCP::Client::CommandStub.reconstruct_from_json(command_string)
            commands[command.name] = command
            # and inject the block for executing over http
            command.execute_block = lambda {
              |req|
              @logger.debug("executing command #{command.name} via http using #{@url}")
              
              res = Net::HTTP.new(@url.host, @url.port).start { |http| http.post("/rhcp/execute", req.to_json()) }
              if (res.code != "200")
                raise RHCP::RhcpException.new("could not execute command using remote server : http status #{res.code} (#{res.message})")
              end
              
              json_response = RHCP::Response.reconstruct_from_json(res.body)
              @logger.debug "json response : #{json_response}"
              json_response
            }
            
            # inject appropriate blocks for all params
            command.params.each do |param|
              param.get_lookup_values_block = lambda {
                |request|
                @logger.debug("getting lookup values for param #{param.name} of command #{command.name} using #{@url}")
                # TODO add caching for lookup values
                $logger.debug("request : #{request}")
                res = Net::HTTP.new(@url.host, @url.port).start { |http| 
                  http.post("/rhcp/get_lookup_values?command=#{command.name}&param=#{param.name}", request.to_json)
                }   
                if (res.code != "200")
                  raise RHCP::RhcpException.new("could not retrieve lookup values from remote server : http status #{res.code} (#{res.message})")
                end
                JSON.parse(res.body)
              }
            end
          end
          commands
        end

      end

    end
    
end  
