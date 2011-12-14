module RHCP
  
  # The context class is used for transporting both the context hash and some
  # other client state like the parameter values that have been collected during
  # user input. It should be sent with all rhcp remote calls and should generally
  # be treated as optional.
  class Context
    
    # hash holding context information; similar to HTTP cookies
    # TODO should we actually use cookies for transporting this info?
    attr_accessor :cookies
    attr_accessor :request_context_id
    
    def initialize(cookies = {}, request_context_id = nil)
      @cookies = cookies
      @request_context_id = request_context_id
      @request_counter = 0
    end       
    
    # def to_json(*args)
      # {
        # 'cookies' => @cookies,
      # }.to_json(*args)
    # end  
#     
    # def self.reconstruct_from_json(json_data)
      # $logger.debug "reconstructing context from json : >>#{json_data}<<"
      # object = JSON.parse(json_data)
      # instance = self.new()
      # instance.cookies = object['cookies'] 
#       
      # instance
    # end

    def incr_and_get_request_counter()
      @request_counter += 1
    end
    
    def to_s
      result = "<Context with #{@cookies.size} cookies>"
      # @cookies.each do |k,v|
        # result += " '#{k}'='#{v}'"
      # end
      # result += ">"
      result
    end
    
  end

end
