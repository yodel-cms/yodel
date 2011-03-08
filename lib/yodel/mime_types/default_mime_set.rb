module Yodel
  module DefaultMimeSet
    def self.load!
      
      Yodel.mime_types do
        mime_type :html do
          extensions 'html', 'htm', 'shtml'
          mime_types 'text/html'
        end
        
        mime_type :json do
          extensions 'json'
          mime_types 'application/json'
          processor do |data|
            data.to_json
          end
        end
      end
      
    end
  end
end
