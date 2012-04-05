require 'webrick'
require 'json'
require 'net/http'

require 'rhcp/broker'
require 'rhcp/request'
require 'rhcp/rhcp_exception'

include WEBrick

module RHCP
  
  # TODO add some logging
  
  # The +HttpExporter+ connects to the RHCP::Broker and exports all commands
  # registered there via http
  # 
  #   /rhcp/get_commands
  #   /rhcp/get_lookup_values
  #   /rhcp/execute
  #
  # All data is transferred in JSON format.
  class HttpExporter
    
    DEFAULT_PORT = 42000
    DEFAULT_PREFIX = "rhcp"
    
    # by default, a new HttpExporter will create it's own +HTTPServer+
    # on port 42000 - if you want to change this port, you can pass the port
    # to use as +port+ option. If you want to use an existing +HTTPServer+
    # instance, you can pass it as +server+ option instead.
    #
    # Also, you can specify the prefix for the rhcp URLs using the +prefix+
    # option - otherwise, all
    # rhcp actions will be exported at 
    #   /rhcp/get_commands
    #   /rhcp/get_lookup_values
    #   /rhcp/execute
    # If you change this, please be aware that all clients that want to connect
    # to this server need to be configured accordingly.
    def initialize(broker, options = Hash.new())
      
      @logger = RHCP::ModuleHelper::instance.logger
      @broker = broker

      # build your own server or use the one passed in as param
      port = options.has_key?(:port) ? options[:port] : DEFAULT_PORT
      
      if options.has_key?(:server)
        @server = options[:server]
        @logger.debug("using existing server #{@server}")
      else        
        @logger.debug("opening own server on port #{port}")
        @server = HTTPServer.new( :Port => port )
      end
      
      @url_prefix = options.has_key?(:prefix) ? options[:prefix] : DEFAULT_PREFIX
      @server.mount_proc("/#{@url_prefix}/") {|req, res|
        res.body = "<HTML>hello (again)</HTML>"
        res['Content-Type'] = "text/html"
      }
      # TODO this path should probably be quite relative
      @server.mount "/#{@url_prefix}/info", HTTPServlet::FileHandler, "docroot"
      @server.mount "/#{@url_prefix}/info2", HTTPServlet::FileHandler, "qooxdoo_rhcp/build"
      
      @server.mount "/#{@url_prefix}/get_commands", GetCommandsServlet, @broker
      @server.mount "/#{@url_prefix}/get_lookup_values", GetLookupValuesServlet, @broker
      @server.mount "/#{@url_prefix}/execute", ExecuteServlet, @broker
      @logger.info("http exporter has been initialized - once started, it will listen on port '#{port}' for URLs starting with prefix '#{@url_prefix}'")
    end
   
    class BaseServlet < HTTPServlet::AbstractServlet
      
      def initialize(server, broker)
        super(server)
        @broker = broker
      end
      
      def do_GET(req, res)
        res['Content-Type'] = "application/json"
        @broker = RHCP::Client::ContextAwareBroker.new(@broker)
        Thread.current['broker'] = @broker
        begin
          @logger.debug("executing #{req}")
        
          begin
            pre_flight_command = @broker.get_command("pre_flight_init")
            request = RHCP::Request.new(pre_flight_command, {}, @broker.context)
            response = @broker.execute(request)
          rescue RHCP::RhcpException
            @logger.warn("no pre_flight command defined")
          end
          do_it(req, res)          
        rescue Exception => ex
          @logger.error("got an exception while executing request . #{ex}\n#{ex.backtrace.join("\n")}")
          
          response = RHCP::Response.new()
          response.mark_as_error(ex.to_s, ex.backtrace.join("\n"))

          res.status = 500
          res.body = response.to_json()
        end
      end
      
      # TODO is this a good idea?
      def do_POST(req, res)
        do_GET(req, res)
      end
      
    end

    class GetCommandsServlet < BaseServlet      
      
      def do_it(req, res)
        context = req.body == nil ?
          RHCP::Context.new() :
          RHCP::Context.reconstruct_from_json(req.body)
          
        commands = @broker.get_command_list(context)
        #puts "about to send back commands : #{commands.values.to_json()}"
        @logger.info("/get_commands returns #{commands.values.size()} commands.")
        res.body = commands.values.to_json()
      end
    end

    class GetLookupValuesServlet < BaseServlet
      
      def do_it(req, res)
        request = RHCP::Request.reconstruct_from_json(@broker, req.body)
        
        #command = @broker.get_command(req.query['command'])
        #param = command.get_param(req.query['param'])
        
        #partial_value = req.query.has_key?('partial') ? req.query['partial'] : ''
        
        req_params = {}
        if req.query_string != nil
          req.query_string.split("&").each do |param_string|
            (key, value) = param_string.split("=")
            req_params[key] = value
          end
        end
        $logger.debug("get_lookup_values for #{req_params['command']}")
        lookup_values = @broker.get_lookup_values(request, req_params['param'])
        
        res.body = lookup_values.to_json()
      end
      
    end

    class ExecuteServlet < BaseServlet
      
      def do_it(req, res)
        @logger.info("got an execute request : #{req}")
        # TODO filter "nocache" parameters from query string
        request = RHCP::Request.reconstruct_from_json(@broker, req.body)

        @logger.debug "http exporter delegating to next broker : #{@broker.class.to_s}"
        response = @broker.execute(request)
        
        response.set_context(@broker.context.cookies)
        
        @logger.debug("sending back response : #{response.to_json()}")
        puts "response : #{response.to_json()}"
        res.body = response.to_json()
      end
      
    end
    
    def run
      @server.start
    end
    
    def start
      puts "about to start server..."
      @thread = Thread.new {     
        puts "in thread; starting server..."        
        @server.start
        puts "in thread: continuing..."
      }      
    end
    
    def stop
      puts "about to stop server"
      @server.stop
      puts "thread stopped"
      # TODO wait until after the server has ended - when this method exits, the server is still shutting down
    end     
      
  end
  
end
