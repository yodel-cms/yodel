module Yodel
  class RecordProxyPage < Page
    def record
      @record ||= record_model.find(params['id'])
    end
    
    def record=(record)
      @record = record
    end
    
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
        status 404 and return unless record
        record.from_form(params)
        
        if record.save
          if after_update_page
            response.redirect after_update_page.path
          else
            render
          end
        else
          if edit_record_page
            edit_record_page.request = request
            edit_record_page.response = response
            flash.now(:record, record)
            edit_record_page.respond_to_get_with_html
          else
            render
          end
        end
      end
      
      with :json do
        status 404 and return unless record
        record.from_json(params['record'])
        record.save
        record.to_json
      end
    end
    
    # create child
    respond_to :post do
      with :html do
        record = record_model.new
        record.from_form(params)
        
        if record.save
          if after_create_page
            response.redirect after_create_page.path
          else
            render
          end
        else
          if new_record_page
            new_record_page.request = request
            new_record_page.response = response
            flash.now(:new_record, record)
            new_record_page.respond_to_get_with_html
          else
            render
          end
        end
      end
      
      with :json do
        record = record_model.new
        record.from_form(params)
        record.save
        record.to_json
      end
    end
  end
end
