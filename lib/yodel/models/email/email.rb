module Yodel
  class Email < Record
    
    def send_email(options)
      mail = Mail.new
      
      # email headers
      %w{to from cc bcc subject}.each do |param|
        mail.send("#{param}=", options[param.to_sym] || self.send(param))
      end
      
      # FIXME: need to create a proper binding class for this; options[:mail] could overwrite mail
      options.each {|key, value| eval "#{key} = \"#{value}\""}
      
      # rendered text body
      unless text_body.blank?
        text_body = self.text_body
        text_part = Mail::Part.new do
          body Ember::Template.new(text_body).render(binding)
        end
        mail.text_part = text_part
      end
      
      # rendered html body
      unless html_body.blank?
        html_body = self.html_body
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body Ember::Template.new(html_body).render(binding)
        end
        mail.html_part = html_part
      end
      
      mail.deliver!
    end
    
  end
end
