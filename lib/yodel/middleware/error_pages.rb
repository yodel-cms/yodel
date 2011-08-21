class ErrorPages
  def initialize(app)
    @app = app
  end
  
  def call(env)
    status, headers, response = @app.call(env)
    if status >= 400
      return render_error_page(status, response)
    else
      return [status, headers, response]
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
      components = []
      response.each {|component| components << component}
      error = components.join
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
      <title><%= error_code %> - <%= error %></title>
      <style type="text/css">
        body {
          background-color: #F3F3F3;
          font-family: HelveticaNeue, Helvetica, sans-serif;
        }

        #modal {
          width: 620px;
          background-color: white;
          border-bottom: 1px solid #e0e0e0;
          border-radius: 5px;
          -moz-border-radius: 5px;
          position: relative;
          margin: 200px auto 0px auto;
          padding: 81px 33px 35px 33px;
        }

        h2 {
          color: #333;
          font-size: 25px;
          font-weight: normal;
          padding: 0px;
          margin: 0px 0px 10px 0px;
        }

        p {
          color: #777;
          font-size: 16px;
          margin: 0px;
          padding: 0px;
        }
        
        #lip {
          position: absolute;
          top: 60px;
          left: -16px;
          width: 0px;
          height: 0px;
          border: 8px solid transparent;
          border-top-color: #E5A700;
          border-right-color: #E5A700;
          padding: 0px;
          margin: 0px;
        }
        
        h1 {
          position: absolute;
          background-color: #FFC900;
          height: 53px;
          width: 170px;
          left: -16px;
          top: 8px;
          padding: 0px;
          margin: 0px;
          color: transparent;
          background-repeat: no-repeat;
          background-position: center 10px;
          background-image: url(/admin/images/yodel.png);
        }
      </style>
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
