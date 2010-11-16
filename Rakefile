require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = 'yodel'
  gem.homepage = 'http://github.com/yodel-cms/yodel'
  gem.license = 'Public Domain'
  gem.summary = 'Ruby CMS'
  gem.description = 'Rack based Ruby CMS'
  gem.email = 'me@willcannings.com'
  gem.authors = ['Will']
  
  gem.files = ["lib/**/*.rb", "lib/**/*.components", "bin/*"]
  
  gem.add_runtime_dependency 'impromptu', 		'~> 1.0'
  gem.add_runtime_dependency 'rack', 					'~> 1.0'
  gem.add_runtime_dependency 'mongo_mapper', 	'~> 0.8.6'
  gem.add_runtime_dependency 'activesupport',	'~> 3.0.0'
  gem.add_runtime_dependency 'erubis',				'~> 2.6.6'
  gem.add_runtime_dependency 'mail',					'~> 2.2.9'
  gem.add_runtime_dependency 'RubyInline',		'~> 3.8.6'
  gem.add_runtime_dependency 'image_science',	'~> 1.2.1'
  gem.add_runtime_dependency 'hpricot',				'~> 0.8.3'
  gem.add_runtime_dependency 'builder',				'~> 2.1.2'
  gem.add_runtime_dependency 'ri_cal',				'~> 0.8.7'
  gem.add_runtime_dependency 'json',					'~> 1.4.6'
  gem.add_runtime_dependency 'rack-contrib',	'~> 1.1.0'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "yodel #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
