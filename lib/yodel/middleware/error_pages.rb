class ErrorPages
  def initialize(app)
    @app = app
  end
  
  def call(env)
    status, headers, response = @app.call(env)
    if status == 200
      return [status, headers, response]
    else
      return render_error_page(status, response)
    end
  rescue
    if Yodel.env.production?
      return render_error_page(500, [])
    else
      raise $!
    end
  end
  
  def render_error_page(error_code, response)
    template = Ember::Template.new(TEMPLATE)
    unless response.empty?
      error = response.join
    else
      error = "We're sorry, but something went wrong."
    end
    if error_code == 404
      description = "You may have mistyped the address or the page may have moved."
    else
      description = "We've been notified about this issue and we'll take a look at it shortly."
    end
    [error_code, {'Content-Type' => 'text/html'}, [template.render(binding)]]
  end

  TEMPLATE = <<HTML
  <!DOCTYPE html>
  <html>
    <head>
      <title><%= error %> (<%= error_code %>)</title>
      <style type="text/css">
        body {
          background-color: #f5f5f5;
          font-family: HelveticaNeue, Helvetica, sans-serif;
        }

        div {
          width: 460px;
          background-color: white;
          border-bottom: 1px solid #eee;
          border-radius: 5px;
          -moz-border-radius: 5px;
          position: relative;
          margin: 200px auto 0px auto;
          padding: 20px 25px;
        }

        h1 {
          color: #333;
          font-size: 20px;
          font-weight: normal;
          padding: 0px;
          margin: 0px 0px 8px 0px;
        }

        p {
          color: #555;
          font-size: 13px;
          margin: 0px;
          padding: 0px;
        }
      </style>
    </head>
    <body>
      <div>
        <h1><%= error_code %> <%= error %></h1>
        <p><%= description %></p>
      </div>
    </body>
  </html>
HTML
end
