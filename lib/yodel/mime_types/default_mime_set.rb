module Yodel
  module DefaultMimeSet
    def self.load!
      
      Yodel.mime_types do
        mime_type :html do
          extensions 'html', 'htm', 'shtml'
          mime_types 'text/html'
          layout_processor :ember
        end
        
        mime_type :json do
          extensions 'json'
          mime_types 'application/json'
          layout_processor :eval
          processor do |data|
            JSON.generate(data)
          end
        end
      end
      
    end
  end
end
