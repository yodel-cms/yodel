module MongoMapper
  module Plugins
    module InheritedSci
      
      module ClassMethods
        def type_and_subtypes
          @type_and_subtypes ||= ([name] + descendants.collect(&:type_and_subtypes)).flatten.compact
        end
        
        def query(options={})
          super.where(_type: type_and_subtypes)
        end
      end
      
    end
  end
end
