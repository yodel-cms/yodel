Dir[File.join(File.dirname(__FILE__), '*.rb')].each do |path|
  require path
end
