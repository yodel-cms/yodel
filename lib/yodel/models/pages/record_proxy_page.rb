class RecordProxyPage < Page
  def record
    @record ||= record_model.find(BSON::ObjectId.from_string(params['id']))
  end
  
  def records
    @records ||= record_model.all
  end
  
  def new_record
    record_model.new
  end
  
  def record=(record)
    @record = record
  end
  
  def form_for(record, options={}, &block)
    if record.new?
      options[:method] = 'post'
      action = path
      if after_create_page
        options[:success] = "window.location = '#{after_create_page.path}';"
      else
        options[:success] = "window.location = '#{path}';"
      end
    else
      options[:method] = 'put'
      action = "#{path}?id=#{record.id}"
      if after_update_page
        options[:success] = "window.location = '#{after_update_page.path}';"
      else
        options[:success] = "window.location = '#{path}';"
      end
    end
    super(record, action, options, &block)
  end
  
  def form_for_new_record(options={}, &block)
    form_for(new_record, options, &block)
  end
  
  # FIXME: a lot of this code is duplicated between html/json, need a way to
  # extract common code to something like
  # respond_to :delete do
  #    record.destroy
  #
  #    with :html do
  #      ...
  
  # show
  respond_to :get do
    # FIXME: security check
    with :html do
      if params['id']
        render_layout(show_record_layout, :html)
      else
        super()
      end
    end
    
    with :json do
      record.to_json
    end
  end
  
  # destroy
  respond_to :delete do
    # FIXME: security check
    with :html do
      record.destroy
      response.redirect after_delete_page.try(:path) || request.referrer || path
    end
    
    with :json do
      record.destroy
      {success: true}
    end
  end
  
  # update
  respond_to :put do
    # FIXME: security check
    with :html do
      raise "Unimplemented"
    end
    
    with :json do
      status 404 and return unless record
      if params.key?('record')
        values = JSON.parse(params['record'])
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
  
  # create
  respond_to :post do
    # FIXME: security check
    with :html do
      raise "Unimplemented"
    end
    
    with :json do
      record = new_record
      
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
