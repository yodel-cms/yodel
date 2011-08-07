class RecordProxyPage < Page
  def record
    @record ||= record_model.find(BSON::ObjectId.from_string(params['id']))
  end
  
  def record=(record)
    @record = record
  end
  
  def form_for(record, options={}, &block)
    options[:method] = record.new? ? 'post' : 'put'
    options[:url] = path
    super(record, options, &block)
  end
  
  def form_for_new_record(options={}, &block)
    form_for(record_model.new, options, &block)
  end
  
  # FIXME: need to include auth checks
  
  # FIXME: a lot of this code is duplicated between html/json, need a way to
  # extract common code to something like
  # respond_to :delete do
  #    record.destroy
  #
  #    with :html do
  #      ...
  
  # show
  respond_to :get do
    with :html do
      render
    end
    
    with :json do
      record.to_json
    end
  end
  
  # destroy
  respond_to :delete do
    with :html do
      record.destroy
      response.redirect after_delete_page.try(:path) || request.referrer || '/'
    end
    
    with :json do
      record.destroy
      {success: true}
    end
  end
  
  # update
  respond_to :put do
    with :html do
      # status 404 and return unless record
      # record.from_form(params)
      # 
      # if record.save
      #   if after_update_page
      #     response.redirect after_update_page.path
      #   else
      #     render
      #   end
      # else
      #   if edit_record_page
      #     # FIXME: need a better way of cross-calling page renders
      #     edit_record_page.request = request
      #     edit_record_page.response = response
      #     flash.now(:record, record)
      #     edit_record_page.respond_to_get_with_html
      #   else
      #     render
      #   end
      # end
      raise "Unimplemented"
    end
    
    with :json do
      # status 404 and return unless record
      # record.from_json(params['record'])
      # record.save
      # record.to_json
      raise "Unimplemented"
    end
  end
  
  # create
  respond_to :post do
    with :html do
      # record = record_model.new
      # record.from_form(params)
      # 
      # if record.save
      #   if after_create_page
      #     response.redirect after_create_page.path
      #   else
      #     render
      #   end
      # else
      #   if new_record_page
      #     new_record_page.request = request
      #     new_record_page.response = response
      #     flash.now(:new_record, record)
      #     new_record_page.respond_to_get_with_html
      #   else
      #     render
      #   end
      # end
      raise "Unimplemented"
    end
    
    with :json do
      #return unless user_allowed_to?(:create)
      record = record_model.new
      
      if params.key?('record')
        vaues = JSON.parse(params['record'])
      else
        values = params
      end

      if record.from_json(values)
        {success: true, record: record}
      else
        {success: false, errors: record.errors}
      end        
    end
    
  end
end
