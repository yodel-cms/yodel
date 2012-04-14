Dir.chdir(File.dirname(__FILE__)) do
  require './validation'
  require './validation_errors'
  Dir['*_validation.rb'].each do |validation|
    require "./#{validation}"
  end
end
