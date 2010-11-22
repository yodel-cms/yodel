module Yodel
  class Environment
    def initialize
      @env = ENV['YODEL_ENV'] || 'development'
    end
    
    def method_missing(sym, *args)
      sym = sym.to_s
      if sym.end_with?('!')
        @env = sym[0..-2]
      elsif sym.end_with?('?')
        @env == sym[0..-2]
      else
        super
      end
    end
  end
end
