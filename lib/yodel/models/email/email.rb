module Yodel
  class Email < Record
    
    def deliver(options)
      Yodel::Task.add_task(:deliver_email, options.merge(id: self.id), site)
    end
    
    def perform_delivery(options)
      mail = Mail.new
      
      # email headers
      %w{to from cc bcc subject}.each do |param|
        mail.send("#{param}=", options[param] || options[param.to_sym] || self.send(param))
      end
      
      # FIXME: need to create a proper binding class for this; options[:mail] could overwrite mail
      render_binding = binding
      options.each {|key, value| render_binding.eval "#{key} = \"#{value}\""}
      
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
        rendered = Ember::Template.new(html_body).render(render_binding)
        if self.html_layout
          # FIXME: reloading should be done elsewhere, not a concern of email
          Yodel::Layout.reload_layouts if Yodel.env.development?
          layout = site.layouts.where(name: self.html_layout, mime_type: :html).first
          if layout.nil?
        end
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body Ember::Template.new(html_body).render(render_binding)
        end
        mail.html_part = html_part
      end
      
      mail.deliver!      
    end
    
  end
end
