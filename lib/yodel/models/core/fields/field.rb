module Yodel
  class Field
    attr_accessor :name
  
    # options is a hash of string keys to values as described. Type
    # is the only required option. All others are optional.
    #
    # type => class/module
    # default => value (value for newly created records)
    # display => true/false
    # searchable => true/false
    # protected => true/false (unable to mass assign to this field if true)
    # section => string (nil or a section name used in admin)
    # required => true/false
    # unique => true/false
    # length => [N, N] (range)
    # format => '/regex/'
    # included_in => array of values
    #
    # Some field types may have other options, such as embedded fields.
    def initialize(name, options={})
      @name = name
      @options = options
    end
  
    def type
      Object.module_eval(@options['type'])
    end
  
    def display?
      @options['display'] != false
    end
  
    def searchable?
      @options['searchable'] != false
    end
  
    def required?
      @options['required'] == true
    end
  
    def unique?
      @options['unique'] == true
    end
  
    def method_missing(name, *args, &block)
      @options[name.to_s]
    end
  
    def validate(value, record, errors)
      Yodel::Validation.validate(self, value, record, errors)
    end
    
    def typecast(value, record)
      value
    end
    
    def untypecast(value, record)
      value
    end
    
    def json_action(action, value, record)
      record.set_raw(name, value)
    end
    
    def from_json(value, record)
      record.set_raw(name, value)
    end
    
    def to_json(*a)
      @options.to_json(*a)
    end
  end
end
