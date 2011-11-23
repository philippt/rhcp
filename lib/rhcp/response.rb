require 'rubygems'
require 'json'

module RHCP

  class Response

    class Status
      OK="ok"
      ERROR="error"
    end

    # TODO these should be attr_reader's, but then we've got to solve json_create() differently
    attr_accessor :status
    attr_accessor :error_text
    attr_accessor :error_detail
    attr_accessor :data
    # TODO this should be called 'cookies'
    attr_accessor :context
    
    # textual description of the result (optional)
    attr_accessor :result_text
    attr_accessor :created_at

    def initialize
      @status = Status::OK
      @error_text = ""
      @error_detail = ""
      @result_text = ""
      @context = nil
      @created_at = Time.now().to_i
    end
    
    def mark_as_error(text, detail="")
      @status = Status::ERROR
      @error_text = text
      @error_detail = detail
    end

    def set_payload(data)
      @data = data
    end

    def set_context(new_context)
      @context = new_context
    end
    
    def as_json(options = {})
      {
        :status => @status,
        :error_text => @error_text,
        :error_detail => @error_detail,
        :data => @data,   # TODO what about JSONinification of data? (probably data should be JSON-ish data only, i.e. no special objects)
        :result_text => @result_text,
        :cookies => @context,
        :created_at => @created_at
      }
    end    

  end

end
