class FormMailerPage < Page
  respond_to :post do
    with :html do
      # ensure any required fields have content
      # TODO: internationalise
      flash['form_errors'] = []
      requirements.each do |field|
        flash['form_errors'] << "#{field.titleize} is required" unless params[field].present?
      end
      
      # redirect to the form if any required fields are empty
      unless flash['form_errors'].empty?
        response.redirect request.referer
        return
      end
      
      # all submitted form values are exposed to emails
      default_options = params.dup
      
      emails.each do |email|
        # emails with a blank 'from' use the value of the email_field key of the submitted form
        options = default_options.dup
        options[:from] = params[email_field].to_s if email.from.blank?
        email.deliver(options)
      end
      
      # redirect after sending emails or failing on requirements
      flash['form_mailed'] = true
      if redirect_url?
        response.redirect redirect_url
      elsif redirect_page?
        response.redirect redirect_page.path
      else
        response.redirect '/'
      end
    end
  end
end
