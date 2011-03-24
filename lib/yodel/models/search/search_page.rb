module Yodel
  class SearchPage < Page
    def query
      q = (type || site.records).where(eval("{#{where}}")).where(show_in_search: true)
      
      # restrict user searching to search_keywords
      unless params['query'].blank?
        q = q.where(search_keywords: params['query'].to_s.split(' ').reject(&:blank?).collect(&:downcase))
      end
      
      # add other optional search parameters
      q = q.sort(sort || params['sort']) if sort || params['sort']
      q = q.limit(limit || params['limit'].to_i) if limit || params['limit']
      q = q.skip(skip || params['skip'].to_i) if skip || params['skip']
      q
    end

    
    respond_to :get do
      with :json do
        {query: query.inspect, results: query.all.collect(&:to_json)}
      end
    end
  end
end
