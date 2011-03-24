$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

require 'test_base'
require 'test/unit'
require 'net/http'

require 'rhcp'


class HttpExporterTest < TestBase
  
  def self.suite    
    puts "gonna setup"
    broker = RHCP::Broker.new()
    broker.register_command(RHCP::Command.new("test", "just a test command", lambda { |req,res| "testing" }))
    broker.register_command(
      RHCP::Command.new("reverse", "reversing input strings", 
        lambda { |req,res| req.get_param_value("input").reverse }
      ).add_param(RHCP::CommandParam.new("input", "the string to reverse", { 
            :lookup_method => lambda { [ "zaphod", "beeblebrox" ] } 
        }))
    )
    
    command = RHCP::Command.new("host_command", "a test command that is enabled for hosts only", lambda {})
    command.enabled_through_context_keys = ['host']
    broker.register_command command
    
    @@broker = broker

    # TODO test other setup options
    @@exporter = RHCP::HttpExporter.new(broker, :port => 42000)
    @@exporter.start()    
    super
  end
  
  def setup
    @url = URI.parse("http://localhost:42000")
  end
  
  def teardown
    #@@exporter.stop
  end
  
  def test_available    
    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.get("/rhcp/") }   
    assert_equal "200", res.code
  end
  
#  def test_info
#    sleep 2
#    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.get("/rhcp/info/index2.html") }   
#    
#    puts res.body
#    assert_equal "200", res.code
#  end
  
  def test_get_commands
    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.get("/rhcp/get_commands") }   
    
    assert_equal "200", res.code
    commands = JSON.parse(res.body)
    
    # +commands+ is an array => convert it back to a hash
    command_hash = Hash.new()
    commands.each do |command_string|
      command = RHCP::Client::CommandStub.reconstruct_from_json(command_string)
      command_hash[command.name] = command
    end
    
    assert_equal [ "test", "reverse" ].sort, command_hash.keys.sort
    assert_kind_of RHCP::Command, command_hash["reverse"]
  end
  
  # we should be able to activate another command by setting the 'host' context cookie
  def test_get_commands_with_context
    context = RHCP::Context.new()
    context.cookies['host'] = 'deepthought'
    
    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.post("/rhcp/get_commands", context.to_json) }   
    
    assert_equal "200", res.code
    commands = JSON.parse(res.body)
    
    # +commands+ is an array => convert it back to a hash
    command_hash = Hash.new()
    commands.each do |command_string|
      command = RHCP::Client::CommandStub.reconstruct_from_json(command_string)
      command_hash[command.name] = command
    end
    
    assert_equal [ "test", "reverse", "host_command" ].sort, command_hash.keys.sort
  end
  
  def test_get_lookup_values
    context = RHCP::Context.new()
    context.cookies['host'] = 'deepthought'
    command = RHCP::Command.new('reverse', '', lambda { |req,res|})
    request = RHCP::Request.new(command, {}, context)
    
    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.post("/rhcp/get_lookup_values?command=reverse&param=input", request.to_json) }
    puts res.body
    assert_equal "200", res.code
    lookups = JSON.parse(res.body)
    assert_equal [ "zaphod", "beeblebrox" ].sort, lookups.sort    
  end
  
  def test_get_lookup_values_invalid_command
    context = RHCP::Context.new()
    context.cookies['host'] = 'deepthought'
    command = RHCP::Command.new('do_the_twist', '', lambda { |req,res|})
    request = RHCP::Request.new(command, {}, context)

    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.post("/rhcp/get_lookup_values?command=do_the_twist", request.to_json ) }
    puts "error response #{res.body}"
    assert_equal "500", res.code
    response = RHCP::Response.reconstruct_from_json(res.body)
    assert(/^no such command/.match(response.error_text))
  end
  
  def test_get_lookup_values_without_params
    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.get("/rhcp/get_lookup_values") }   
    puts "error response #{res.body}"
    assert_equal "500", res.code    
  end
  
  # TODO reactivate
  def test_get_lookup_values_partial
    return
    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.get("/rhcp/get_lookup_values?command=reverse&param=input&partial=zap") }   
    puts res.body
    assert_equal "200", res.code
    lookups = JSON.parse(res.body)
    assert_equal [ "zaphod" ].sort, lookups.sort
  end

  def test_execute
    request = RHCP::Request.new(@@broker.get_command("reverse"), {
      "input" => [ "zaphod" ]
    })
    
    res = Net::HTTP.new(@url.host, @url.port).start { |http| http.post("/rhcp/execute", request.to_json) }
    puts "execute response #{res.body}"    
    assert_equal "200", res.code    
  end
  
  def test_execute_fails
    # TODO write test
  end
  
end
