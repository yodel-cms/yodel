module Yodel
  class Queue
    def initialize(conditions)
      @conditions = conditions.merge(locked: nil)
    end
    
    def pop
      options = {query: @conditions, update: {'$set' => {locked: Time.now}}, sort: ['created_at', 1]}
      document = Yodel::Task.collection.find_and_modify(options)
      return nil if document.nil?
      site = Site.find_by(_id: document['_site_id'])
      
      # FIXME: write error to log here
      if site.nil?
        Yodel::Task.collection.remove(_id: document['_id'])
        return nil
      end
      
      Yodel::Task.new(site, document)
    rescue Mongo::OperationFailure
      return nil
    end
  end
end
