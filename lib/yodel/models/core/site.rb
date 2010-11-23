module Yodel
  class Site
    include ::MongoMapper::Document
    has_many :records, class: Yodel::Model, dependent: :destroy
    
    key :name, String, required: true
    key :identifier, String, required: true
    key :domains, Array, required: true, default: [], index: true
    key :extensions, Array, required: true, default: []
    
    def self.find_by_domain(domain)
      where(domains: domain).first
    end
    
    def self.find_by_identifier(identifier)
      where(identifier: identifier).first
    end
    
    def directory_path
      @directory_path ||= Yodel.config.public_directory.join(self.identifier)
    end
  end
end
