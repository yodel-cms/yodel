require 'bundler/gem_tasks'
require 'minitest/unit'

task :test do
  # boot yodel and initialise the test site
  $:.unshift('.')
  require './test/setup'
  
  # run each test suite
  Dir['./test/test_*'].each {|path| require path}
  MiniTest::Unit.new.run
  
  # destroy the test site
  require './test/teardown'
  
  # exit without re-running the Test::Unit autorunner
  # (installed as an at_exit block)
  Process.exit!(true)
end

task :default => :test
