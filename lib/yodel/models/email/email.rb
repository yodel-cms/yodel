class Email < Record
  
  def deliver(options)
    # we don't store complete records in the queue task, only IDs of records
    cleaned = {_id: self.id}
    options.each do |key, value|
      if value.is_a?(Record)
        value = {_id: value.id}
      end
      cleaned[key] = value
    end
    
    Task.add_task(:deliver_email, cleaned, site)
  end
  
  def perform_delivery(options)
    # TODO: validate at least to and from exist
    mail = Mail.new
    
    # retrieve records that were replaced with their ID as above
    options.each do |key, value|
      if value.is_a?(Hash) && value.key?('_id')
        options[key] = site.records.find(value['_id'])
      end
    end
    
    # email headers
    %w{to from cc bcc subject}.each do |param|
      options[param] ||= options[param.to_sym] || self.send(param)
      mail.send("#{param}=", options[param])
    end
    render_binding = binding
    
    # rendered text body
    unless text_body.blank?
      text_body = self.text_body
      text_part = Mail::Part.new do
        body Ember::Template.new(text_body).render(render_binding)
      end
      mail.text_part = text_part
    end
    
    # rendered html body
    unless html_body.blank?
      html_body = self.html_body
      # FIXME: reloading should be done elsewhere, not a concern of email
      #Layout.reload_layouts(site) if Yodel.env.development?        
      if self.html_layout && layout = site.layouts.where(name: self.html_layout, mime_type: :html).first
        @content = Ember::Template.new(html_body).render(render_binding)
        @binding = render_binding
        html_content = layout.render(self)
      else
        html_content = Ember::Template.new(html_body).render(render_binding)
      end
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body html_content
      end
      mail.html_part = html_part
    end
    
    mail.deliver!      
  end
  
  def content
    @content
  end
  
  def set_content(content)
    @content = content
  end
  
  def get_binding
    @binding
  end
  
  def set_binding(binding)
    @binding = binding
  end
end
