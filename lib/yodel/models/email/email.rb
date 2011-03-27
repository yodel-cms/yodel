module Yodel
  class Email < Record
    
    def send_email(options)
      mail = Mail.new
      
      # email headers
      %w{to from cc bcc subject}.each do |param|
        mail.send("#{param}=", options[param.to_sym] || self.send(param))
      end
      
      # rendered text body
      unless text_body.blank?
        text_part = Mail::Part.new do
          body Erubis::Eruby.new(text_body).evaluate(options)
        end
        mail.text_part = text_part
      end
      
      # rendered html body
      unless html_body.blank?
        html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body Erubis::Eruby.new(html_body).evaluate(options)
        end
        mail.html_part = html_part
      end
      
      mail.deliver!
    end
    
  end
end
