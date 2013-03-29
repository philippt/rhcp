module RHCP
  
  class RhcpException < StandardError
    
    def initialize(msg, detail = nil)
      e = super(msg)
      e.set_backtrace(detail) if detail
      e
    end
    
  end
  
end
