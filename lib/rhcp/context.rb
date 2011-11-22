module RHCP
  
  # The context class is used for transporting both the context hash and some
  # other client state like the parameter values that have been collected during
  # user input. It should be sent with all rhcp remote calls and should generally
  # be treated as optional.
  class Context
    
    # hash holding context information; similar to HTTP cookies
    # TODO should we actually use cookies for transporting this info?
    attr_accessor :cookies
    
    def initialize(cookies = {})
      @cookies = cookies
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
