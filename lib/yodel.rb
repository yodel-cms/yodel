require 'impromptu'

Impromptu.define_components do
  parse_file File.join(File.dirname(__FILE__), 'yodel.components')
end
