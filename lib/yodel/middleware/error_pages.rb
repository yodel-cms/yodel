class ErrorPages
  def initialize(app)
    @app = app
  end
  
  def call(env)
    status, headers, response = @app.call(env)
    if status.to_i >= 400 && status.to_i != 401
      return render_error_page(status, response)
    else
      return [status, headers, response]
    end
  rescue
    Yodel.config.logger.warn $!.to_s
    if Yodel.env.production?
      if $!.is_a?(DomainNotFound)
        return render_error_page(404, ['No site has been set up at this address'])
      else
        return render_error_page(500, [])
      end
    else
      if $!.respond_to?(:error) && $!.respond_to?(:description)
        return render_error_page(404, $!.error, $!.description)
      else
        raise $!
      end
    end
  end
  
  def render_error_page(error_code, response, description=nil)
    template = Ember::Template.new(TEMPLATE)
    if response.present? && response.respond_to?(:length) && response.length > 0
      components = []
      response.each {|component| components << component}
      error = components.join
    elsif error_code == 403
      error = "Unauthorised"
    else
      error = "We're sorry, but something went wrong."
    end
    if description.nil?
      if error_code == 404
        description = "You may have mistyped the address or the page may have moved."
      elsif error_code == 403
        description = "You must log in before performing this action."
      else
        description = "We've been notified about this issue and we'll take a look at it shortly."
      end
    end
    [error_code, {'Content-Type' => 'text/html'}, [template.render(binding)]]
  end

  TEMPLATE = <<HTML
  <!DOCTYPE html>
  <html>
    <head>
      <title><%= error_code %> - <%= error %></title>
      <link rel="stylesheet" href="/core/css/core.css" type="text/css">
    </head>
    <body>
      <article id="modal">
        <header>
          <h1>yodel</h1>
          <div id="lip"></div>
        </header>
        <h1><%= error %></h1>
        <p><%= description %></p>
      </article>
    </body>
  </html>
HTML
end
