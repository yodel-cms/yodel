module Yodel
  class Route
    include ::MongoMapper::EmbeddedDocument
    key :method, String, required: true
    key :original_path, String, required: true
    key :regex_path, String, required: true
    key :controller, String, required: true
    key :action, String, required: true
    key :index, Integer, required: true
    
    # Input paths (such as /admin/records/) are not used to match incoming
    # requests, instead we reformat the path in to a regex that allows for
    # misformed paths, file extensions and globs
    def path=(path)
      self.original_path = path
      self.regex_path = "^#{path.chomp('/').gsub('/', '/+')}(?<glob>.*?)(\\.(?<format>\\w+))?$"
    end
    
    # TODO: sites should be cached compiled route path regex's so we don't
    # recreate the regex object each request
    def match(request_path, request_method)
      return nil unless self.method == 'any' || self.method == request_method
      Regexp.new(self.regex_path, nil, 'n').match(request_path)
    end
    
    # Turn a path with options into a concrete path by filling the options
    # in with values (/page/:id with {id: 1} becomes /page/1)
    def path_with_options(options={})
      rendered_path = self.original_path.dup
      options.each do |name, value|
        rendered_path.gsub!(/\(\?\<#{name}\>.+\)/, value.to_s)
      end
      OpenStruct.new(path: rendered_path, method: self.method)
    end
  end
end
