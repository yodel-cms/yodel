Dir.chdir(File.dirname(__FILE__)) do
  require './attachments/attachment'
  require './attachments/image'
  require './fields/fields'
  require './validations/validations'
  require './associations/associations'
  require './mongo/mongo'
  require './record/record'
  require './model/model'
  require './functions/functions'
  require './log/log'  
  require './migration'
  require './site'
end
