module Yodel
  module AbstractModel
    module InstanceMethods
      def fields
        self.class.fields
      end
    end
    
    module ClassMethods
      def fields
        @fields ||= {}
      end
      
      def field(name, type, options={})
        fields[name.to_s] = Yodel::Field.new(name.to_s, {'type' => type}.merge(options))
      end
    end
    
    def self.included(mod)
      mod.send(:include, Yodel::AbstractModel::InstanceMethods)
      mod.send(:extend, Yodel::AbstractModel::ClassMethods)
    end
  end
end
