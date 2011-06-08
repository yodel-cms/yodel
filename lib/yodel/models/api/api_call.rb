module Yodel
  class APICall < Record
    def call(data)
      Yodel::Task.add_task(:call_api, encode_data_hash(data), site)
    end
    
    def perform_call(data)
      data = decode_data_hash(data)
      mime = Yodel.mime_types[mime_type.to_sym]
      headers = {'Content-Type' => mime.default_mime_type}
      
      # FIXME: reloading should be done elsewhere, not a concern of APICall
      #Yodel::Layout.reload_layouts(site) if Yodel.env.development?
      if body_layout && layout = site.layouts.where(name: body_layout, mime_type: mime_type).first
        @data = data
        set_content(body)
        set_binding(binding)
        payload = mime.process(layout.render(self))
      else
        payload = body
      end
      
      Net::HTTP.start(domain, port) do |http|
        request = request_class.new(path, headers)
        case authentication
        when 'basic'
          request.basic_auth username, password
        when 'digest'
          # FIXME: implement
        end
        response = http.request(request, payload)
        Yodel::Function.new(function).execute(binding)
      end
    end
    
    
    def content
      @content
    end
    
    def set_content(content)
      @content = content
    end
    
    def get_binding
      @binding
    end
    
    def set_binding(binding)
      @binding = binding
    end
    
    def data
      @data
    end
    
    
    private
      def encode_data_hash(data)
        ({_id: self.id}).tap do |encoded|
          data.each do |key, value|
            value = {_id: value.id} if value.is_a?(Record)
            encoded[key] = value
          end
        end
      end
      
      def decode_data_hash(data)
        data.each do |key, value|
          if value.is_a?(Hash) && value.key?('_id')
            data[key] = site.records.find(value['_id'])
          end
        end
      end
      
      def request_class
        case self.http_method.downcase
        when 'get'
          Net::HTTP::Get
        when 'post'
          Net::HTTP::Post
        when 'put'
          Net::HTTP::Put
        when 'delete'
          Net::HTTP::Delete
        end
      end
  end
end
