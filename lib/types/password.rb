class Password < String
  class << self
    undef search_terms_set
  end
end
