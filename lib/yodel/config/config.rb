Dir.chdir(File.dirname(__FILE__)) do
  require './environment'
  require './yodel'
end

class YodelConfig
  def initialize
    @options = {
      'yodel_migration_directory' => File.join(File.dirname(__FILE__), '..', 'models', 'migrations'),
      'public_directories' => [File.join(File.dirname(__FILE__), '..', 'public')],
      'layout_directories' => [],
      'extensions' => []
    }
  end
  
  def method_missing(method, *args)
    method = method.to_s
    if method[-1] == '='
      @options[method[0...-1]] = args[0]
    elsif method[-1] == '?'
      @options.has_key?(method[0...-1])
    else
      @options[method]
    end
  end
  
  def define(&block)
    yield self
  end
end
