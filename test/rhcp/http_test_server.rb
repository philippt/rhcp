$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'rhcp'

require 'net/http'
require 'logger'

$logger = Logger.new($stdout)

broker = RHCP::Broker.new()
test_command = RHCP::Command.new("test", "just a test command", lambda { |req,res| "testing" })
broker.register_command(test_command)

hello_command = RHCP::Command.new("hello", "another test command", lambda { |req, res| "hello world" })
hello_command.mark_as_read_only()
broker.register_command(hello_command)

broker.register_command(
  RHCP::Command.new("reverse", "reversing input strings", 
    lambda { |req,res| req.get_param_value("input").reverse }
  ).add_param(RHCP::CommandParam.new("input", "the string to reverse", { 
        :lookup_method => lambda { [ "zaphod", "beeblebrox" ] } 
    }))
)
broker.register_command RHCP::Command.new("cook", "cook something nice out of some ingredients", 
  lambda { |req,res| 
    ingredients = req.get_param_value("ingredient").join(" ")
    puts "cooking something with #{ingredients}"
    ingredients
  }
  ).add_param(RHCP::CommandParam.new("ingredient", "something to cook with", 
      { 
        :lookup_method => lambda { [ "mascarpone", "chocolate", "eggs", "butter", "marzipan" ] },
        :allows_multiple_values => true,
        :mandatory => true
      }
  )
)

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text)
  colorize(text, 31)
end

def green(text)
  colorize(text, 32)
end


command = RHCP::Command.new("list_stuff", "this command lists stuff", 
  lambda { |req,res|
    res.set_context({"prompt" => green("what have the romans brought us $ ")})
    [ "peace", "aquaeduct", "education" ]
  }
)
command.mark_as_read_only()
command.result_hints[:display_type] = "list"
broker.register_command command

command = RHCP::Command.new("build_table", "this command returns tabular data", 
  lambda { |req,res|
    [ 
      { :the_first_name => "Zaphod", :last_name => "Beeblebrox", :heads => 2, :character => "dangerous" },
      { :the_first_name => "Arthur", :last_name => "Dent", :heads => 1, :character => "harmless (mostly)" },
      { :the_first_name => "Prostetnik", :last_name => "Yoltz (?)", :heads => 1, :character => "ugly" }
    ]
  }
)
command.mark_as_read_only()
command.result_hints[:display_type] = "table"
command.result_hints[:overview_columns] = [ "the_first_name", "last_name" ]
command.result_hints[:column_titles] = [ "First Name", "Last Name" ]
broker.register_command command

logging_broker = RHCP::LoggingBroker.new(broker)
context_aware_broker = RHCP::Client::ContextAwareBroker.new(logging_broker)

complicated_command = RHCP::Command.new("complicated", "just testing",
  lambda { |req, res|
    request = RHCP::Request.new(test_command, Hash.new())
    context_aware_broker.execute(request)

    hello_request = RHCP::Request.new(hello_command, Hash.new())
    context_aware_broker.execute(hello_request)

    hello_request2 = RHCP::Request.new(hello_command, Hash.new())
    context_aware_broker.execute(hello_request2)
  }
)
broker.register_command complicated_command


exporter = RHCP::HttpExporter.new(logging_broker, :port => 42000)

trap("INT") {
  exporter.stop
  Kernel.exit 0
}

$logger.info "launching http exporter..."
exporter.start()
while (true) do
  sleep 30
  puts "."
end
$logger.info "exiting"
