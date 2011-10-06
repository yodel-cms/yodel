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
    if Yodel.env.production?
      return render_error_page(500, [])
    else
      if $!.respond_to?(:domain)
        return render_error_page(404, $!.error, $!.description)
      else
        raise $!
      end
    end
  end
  
  def render_error_page(error_code, response, description=nil)
    template = Ember::Template.new(TEMPLATE)
    unless response.empty?
      components = []
      response.each {|component| components << component}
      error = components.join
    else
      error = "We're sorry, but something went wrong."
    end
    if description.nil?
      if error_code == 404
        description = "You may have mistyped the address or the page may have moved."
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
      <div id="modal">
        <div id="lip"></div>
        <h1>yodel</h1>
        <h2><%= error %></h2>
        <p><%= description %></p>
      </div>
    </body>
  </html>
HTML
end
