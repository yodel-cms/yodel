Yodel.mime_types do
  mime_type :html do
    extensions 'html', 'htm', 'shtml'
    mime_types 'text/html'
    auth_type :page
    layout_processor :ember
  end
  
  mime_type :json do
    extensions 'json'
    mime_types 'application/json'
    layout_processor :eval
    auth_type :basic
    processor do |data|
      JSON.generate(data)
    end
  end
  
  mime_type :atom do
    extensions 'atom'
    mime_types 'application/atom+xml'
    layout_processor :eval
    auth_type :basic
    builder do
      Builder::XmlMarkup.new
    end
  end
end
