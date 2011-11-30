class RecordProxyPage < Page
  def record
    @record ||= decorate_record(find_record(BSON::ObjectId.from_string(params['id'])))
  end
  
  def records
    @records ||= all_records.map {|record| decorate_record(record)}
  end
  
  def new_record
    decorate_record(construct_record)
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
  
  # FIXME: all json requests should be standardised to {success: true/false}
  # i.e get needs to change from record.to_json to {success: true, record: record}
  
  # FIXME: change get to pass record through format_record
  
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
        format_record(record).merge({success: true})
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
        format_record(record).merge({success: true})
      else
        {success: false, errors: record.errors}
      end        
    end
    
  end
  
  
  # record interaction and decoration. all_records, find_record and
  # construct_record can be overriden for records which can't be
  # retrieved from a record_model (such as Site or Task)
  # override format_record to change the way records are returned
  # to json requests, either reformatting the record itself, or
  # adding new keys to the response object
  private
    def decorate_record(record)
      record.tap do |record|
        # if the record mixes in another model which has already
        # included HTMLDecorator, undef these methods so record
        # proxy page can handle them instead. When a model is
        # mixed in, forwardable creates 
        if record.methods(false).include?(:delete_link)
          class << record
            HTMLDecorator.instance_methods.each do |method_name|
              remove_method method_name
            end
          end
        end

        record.instance_variable_set('@record_proxy', self)
        record.extend HTMLDecorator
        record.instance_eval "
          class << self
            def path
              \"#{path}?id=#{record.id}\"
            end
            alias :path_was :path
            
            def form_for(record, options={}, &block)
              @record_proxy.form_for(record, options, &block)
            end
          end
        "
      end
    end
    
    def all_records
      record_model.all
    end
    
    def find_record(id)
      record_model.find(id)
    end
    
    def construct_record
      record_model.new
    end
    
    def format_record(record)
      {record: record}
    end
end
