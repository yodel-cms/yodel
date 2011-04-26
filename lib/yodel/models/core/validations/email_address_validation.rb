module Yodel
  class EmailAddressValidation < Validation
    def self.validate(params, field, name, value, record, errors)
      begin
        # modified: http://my.rails-royce.org/2010/07/21/email-validation-in-ruby-on-rails-without-regexp/
        address = Mail::Address.new(value)
      
        # ensure there is a domain and the full parsed address is equivalent to the value
        if address.domain.present? && address.address == value
          # ensure the domain component is made up of more than just a TLD
          domain_tree = address.send(:tree).domain
          if domain_tree.dot_atom_text.elements.size > 1
            return true
          end
        end
      rescue
      end
      
      errors[field.name] << new(name)
    end
  
    def describe
      "must be a valid email address"
    end
  end
end
