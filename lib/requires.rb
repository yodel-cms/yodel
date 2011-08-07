require 'logger'
require 'forwardable'
require 'bigdecimal'
require 'date'
require 'ostruct'
require 'net/http'
require 'open-uri'

# load bundled gems
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

# manually load active support extensions
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/array/conversions'
