require 'impromptu'

Impromptu.define_components do
  parse_file ::File.join(::File.dirname(__FILE__), 'yodel.components')
  
  # load application specific extensions
  Dir['extensions/*'].each do |path|
    component "yodel.extensions.#{::File.basename(path)}" do
      folder ::File.absolute_path(::File.join(path, 'models')), namespace: :Yodel
    end
  end
end
