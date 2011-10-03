Dir.chdir(File.join(File.dirname(__FILE__), 'yodel')) do
  # ensure gem dependencies are loaded
  require './requires'
  
  # rack extensions
  require './middleware/request'
  require './middleware/error_pages'
  require './middleware/site_detector'
  require './middleware/runtime'
  
  # type extensions
  require './types/date'
  require './types/object_id'
  require './types/time'
  
  # core yodel
  require './application/application'
  require './exceptions/exceptions'
  require './mime_types/mime_types'
  require './request/request'
  require './models/models'
  require './task_queue/task_queue'
end
