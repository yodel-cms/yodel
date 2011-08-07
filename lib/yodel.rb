$:.unshift('.')

Dir.chdir(File.dirname(__FILE__)) do
  # rack extensions
  require 'middleware/rack/request'
  require 'middleware/yodel/conditional_file'
  
  # type extensions
  require 'types/date'
  require 'types/object_id'
  require 'types/time'
  
  # core yodel
  require 'yodel/application/application'
  require 'yodel/exceptions/exceptions'
  require 'yodel/mime_types/mime_types'
  require 'yodel/request/request'
  require 'yodel/models/models'
  require 'yodel/task_queue/task_queue'
end
