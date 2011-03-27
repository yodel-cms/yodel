class String
  extend YodelTypeInterface
  
  def self.search_terms_set(str)
    str.gsub(/\W+/, ' ').split
  end
end
