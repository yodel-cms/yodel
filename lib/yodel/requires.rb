require 'logger'
require 'forwardable'
require 'bigdecimal'
require 'date'
require 'ostruct'
require 'net/http'
require 'open-uri'
require 'fileutils'
require 'uri'

# load bundled gems
ENV['BUNDLE_GEMFILE'] = File.join(File.dirname(__FILE__), '..', '..', 'Gemfile')
require 'rubygems'
require 'bundler'
Bundler.require

# manually load active support extensions
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/array/conversions'

# config and environment are loaded separately
# from yodel, so a configuration can be created
# before loading the server or console
require File.join(File.dirname(__FILE__), 'config', 'config')
if $settings
  require $settings
else
  require '/usr/local/etc/yodel/settings.rb'
end

