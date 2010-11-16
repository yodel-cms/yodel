module Yodel
  class Route
    attr_accessor :method, :original_path, :path, :controller, :action
    def initialize(route)
      @method = route[:method].to_s.downcase.to_sym
      @original_path = route[:path]
      @path = Regexp.new("^#{route[:path].chomp('/').gsub('/', '/+')}(?<glob>.*?)(\\.(?<format>\\w+))?$", nil, 'n')
      @controller = route[:controller]
      @action = route[:action]
      @last = route[:last]
    end

    def match(path, request_method)
      return nil unless @method == :any || @method == request_method
      @path.match(path)
    end

    def path_with_options(options={})
      path = @original_path.dup
      options.each do |name, value|
        path.gsub!(/\(\?\<#{name}\>.+\)/, value.to_s)
      end
      OpenStruct.new(path: path, method: @method)
    end

    def last?
      @last
    end
  end  
end
