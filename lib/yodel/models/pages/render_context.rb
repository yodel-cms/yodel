module Yodel
  class RenderContext
    def initialize(page)
      @page = page
      @content = page.content
    end
  
    def method_missing(name, *args)
      name = name.to_s
    
      unless name.starts_with?('@')
        if @page.respond_to?(name.to_sym)
          @page.send(name.to_sym, *args)
        else
          nil
        end
      else
        if name.ends_with?('=')
          instance_variable_set name[0...-1], args.first
        elsif name.ends_with?('?')
          instance_variable_defined? name[0...-1]
        else
          instance_variable_defined?(name) ? instance_variable_get(name) : nil
        end
      end
    end
  
    def variabalise_name(name)
      '@' + name.to_s.gsub(' ', '').underscore
    end
  
    def set_value(name, value)
      instance_variable_set variabalise_name(name), value
    end
  
    def get_value(name)
      instance_variable_get variabalise_name(name)
    end
  end
end
