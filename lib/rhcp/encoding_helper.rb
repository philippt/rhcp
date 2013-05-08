require 'base64'

module RHCP
  
  module EncodingHelper
    
    def self.change_string_values(thing, &block)
      result = nil
      case thing.class.to_s
      when "Array"
        result = []
        thing.each do |t|
          result << change_string_values(t, &block)
        end
      when "Hash"
        result = {}
        thing.each do |k,v|
          result[k] = change_string_values(v, &block)
        end
      when "String","Fixnum","Boolean","TrueClass","FalseClass"
        result = block.call(thing.to_s)
      when "Proc","NilClass"
        # ignore
      else
        $logger.warn("don't know how to handle #{thing.class} - skipping")
      end
      result
    end

    def self.to_base64(thing)
      change_string_values(thing) do |x|
        Base64.encode64(x)
      end
    end
    
    def self.from_base64(thing)
      change_string_values(thing) do |x|
        Base64.decode64(x)
      end
    end
    
  end
end