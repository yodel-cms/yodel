module Yodel
  class Field
    attr_accessor :name, :options
    
    # TODO: this should automatically be generated
    TYPES = {
      'array' => Yodel::ArrayField,
      'boolean' => Yodel::BooleanField,
      'date' => Yodel::DateField,
      'decimal' => Yodel::DecimalField,
      'email' => Yodel::EmailField,
      'enum' => Yodel::EnumField,
      'fields' => Yodel::FieldsField,
      'filtered_string' => Yodel::FilteredStringField,
      'filtered_text' => Yodel::FilteredTextField,
      'hash' => Yodel::HashField,
      'html' => Yodel::HTMLField,
      'integer' => Yodel::IntegerField,
      'password' => Yodel::PasswordField,
      'string' => Yodel::StringField,
      'tags' => Yodel::TagsField,
      'text' => Yodel::TextField,
      'time' => Yodel::TimeField,
      'many_embedded' => Yodel::ManyEmbeddedAssociation,
      'one_embedded' => Yodel::OneEmbeddedAssociation,
      'many_store' => Yodel::ManyStoreAssociation,
      'one_store' => Yodel::OneStoreAssociation,
      'many_query' => Yodel::ManyQueryAssociation,
      'one_query' => Yodel::OneQueryAssociation
    }
    
    def self.from_options(name, options)
      field_from_type(options['type']).new(name, options)
    end
    
    def self.field_from_type(type)
      TYPES[type]
    end
    
    # options is a hash of string keys to values as described. Type
    # is the only required option. All others are optional.
    #
    # type => field type
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
      @options = options.stringify_keys
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
    
    def strip_nil?
      @options['strip_nil'] == true
    end
    
    def index?
      @options['index'] == true
    end
    
    def numeric?
      false
    end
  
    def method_missing(name, *args, &block)
      @options[name.to_s]
    end
  
    def validate(value, record, errors)
      Yodel::Validation.validate(self, value, record, errors)
    end
    
    # Convert from an untypecast (raw) representation of a value to a
    # more complex version of the same value. For instance, BigDecimals
    # are stored as strings, but are BigDecimal objects when typecast.
    def typecast(value, record)
      value
    end
    
    # Convert from a complex (typecast) representation of a value to a
    # simpler version of the same value. For instance, BigDecimals are
    # BigDecimal objects when typecast, but are strings when untypecast.
    def untypecast(value, record)
      value
    end
    
    # Example json_action implementation; only implement this method if
    # the field type supports actions other than just 'set'
    # def json_action(action, value, record)
    #   record.set_raw(name, from_json(value, record))
    # end
    
    # Take a raw JSON value and encode it in an untypecast (raw) value
    # ready for storage in a mongo record. Non mongo records can still
    # use this method since it performs complex->simple type conversion.
    def from_json(value, record)
      value
    end
    
    # JSON converter for the field object itself; this method does not
    # encode a field's value. Fields convert values to and from mongo
    # (untypecast/typecast) and from json (from_json). When converting
    # a record to JSON, the raw (untypecast) value is used. If this
    # value needs special encoding for JSON, specify a to_json(*a)
    # method on the class the value is an instance of. For instance,
    # Time fields store values as Time objects in mongo. For conversion
    # to JSON, the Time class is extended with a to_json(*a) method to
    # perform the necessary conversion. This is done so fields can be
    # ignored by the JSON converter, and a simple conversion done between
    # untypecast values and JSON. Since mongo stores values in BSON (which
    # is similar to JSON), this makes conversion much faster.
    def to_json(*a)
      @options.to_json(*a)
    end
    
    # Record callbacks. These methods are called at various stages of a
    # record's life cycle. Only implement them when necessary.
    # def before_create(record)
    # end
    # 
    # def before_update(record)
    # end
    # 
    # def before_save(record)
    # end
    # 
    # def before_destroy(record)
    # end
    #
    # def after_create(record)
    # end
    # 
    # def after_update(record)
    # end
    # 
    # def after_save(record)
    # end
    # 
    # def after_destroy(record)
    # end
  end
end
