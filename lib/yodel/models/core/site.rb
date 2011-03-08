module Yodel
  class Site
    include ::MongoMapper::Document
    has_many :records, class: Yodel::Model, dependent: :destroy
    
    key :domains, Array, required: true, default: ['localhost', '127.0.0.1', '0.0.0.0'], index: true
    key :extensions, Array, required: true, default: ['Admin']
    key :name, String, required: true
  end
end
