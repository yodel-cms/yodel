require 'mongo_mapper'
require 'impromptu'
require 'rack'
require File.join(File.dirname(__FILE__), 'mongo_mapper', 'inherited_sci')

# FIXME: to stop an error in the way impromptu loads extensions to resources defined
# by dependencies of a component, we need to include rack and mongo before defining
# resources. We also need to pre-load the mongo extension.

Impromptu.define_components do
  parse_file File.join(File.dirname(__FILE__), 'yodel.components')
end
