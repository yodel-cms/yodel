Dir.chdir(File.join(File.dirname(__FILE__), 'yodel')) do
  # rack extensions
  require 'middleware/request'
  
  # type extensions
  require 'types/date'
  require 'types/object_id'
  require 'types/time'
  
  # core yodel
  require 'application/application'
  require 'exceptions/exceptions'
  require 'mime_types/mime_types'
  require 'request/request'
  require 'models/models'
  require 'task_queue/task_queue'
end
