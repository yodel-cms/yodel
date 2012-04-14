class EmailAddressValidation < Validation
  validate do
    begin
      # modified: http://my.rails-royce.org/2010/07/21/email-validation-in-ruby-on-rails-without-regexp/
      address = Mail::Address.new(value)
    
      # ensure there is a domain and the full parsed address is equivalent to the value
      if address.domain.present? && address.address == value
        # ensure the domain component is made up of more than just a TLD
        domain_tree = address.send(:tree).domain
        if domain_tree.dot_atom_text.elements.size > 1
          return
        end
      end
    rescue
    end
    
    invalidate_with("must be a valid email address")
  end
end
