module Yodel
  class Query < Plucky::Query
    # construct a default scope for queries on a model. we need to use the raw_values
    # version of descendants because typecasting relies on model objects, and constructing
    # the root model object is done before any other models are.
    def initialize(model, site_id, descendants=nil)
      @model = model
      
      if descendants
        super(Yodel::Record::COLLECTION, _site_id: site_id, _model: descendants)
      else
        super(Yodel::Record::COLLECTION, _site_id: site_id)
      end
    end

    def all(opts={})
      super.collect {|document| @model.load(document)}
    end

    def first(opts={})
      @model.load(super)
    end

    def last(opts={})
      @model.load(super)
    end
  end
end
