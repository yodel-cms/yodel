# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'yodel/version'

Gem::Specification.new do |s|
  s.name        = 'yodel'
  s.version     = Yodel::VERSION
  s.authors     = ['Will Cannings']
  s.email       = ['me@willcannings.com']
  s.homepage    = 'http://yodelcms.com'
  s.summary     = 'Yodel CMS'
  s.description = 'Yodel CMS'
  s.licenses    = ["Public Domain"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'bundler',        '~> 1.0.21'
  s.add_runtime_dependency 'rack',           '~> 1.3.3'
  s.add_runtime_dependency 'mongo',          '~> 1.3.1'
  s.add_runtime_dependency 'bson',           '~> 1.3.1'
  s.add_runtime_dependency 'bson_ext',       '~> 1.3.1'
  s.add_runtime_dependency 'plucky',         '~> 0.4.1'
  s.add_runtime_dependency 'activesupport',  '~> 3.0.3'
  s.add_runtime_dependency 'ember',          '~> 0.3.1'
  s.add_runtime_dependency 'mail',           '~> 2.3.0'
  s.add_runtime_dependency 'hpricot',        '~> 0.8.4'
  s.add_runtime_dependency 'json',           '~> 1.6.1'
  s.add_runtime_dependency 'rack-contrib',   '~> 1.1.0'
  s.add_runtime_dependency 'rubydns',        '~> 0.3.3'
  s.add_runtime_dependency 'git',            '~> 1.2.5'
  s.add_runtime_dependency 'highline',       '~> 1.6.2'
  s.add_runtime_dependency 'mini_magick',    '~> 3.3'

  # extensions
  s.add_runtime_dependency 'yodel_admin'
  s.add_runtime_dependency 'yodel_queue'
  s.add_runtime_dependency 'yodel_blog'

  # environment support sites
  s.add_runtime_dependency 'yodel_development_environment'
  s.add_runtime_dependency 'yodel_production_environment'
end
