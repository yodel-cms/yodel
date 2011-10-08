require 'rack/utils'
require 'rack/mime'

# some code copied from Rack::File
class PublicAssets
  SEPARATORS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)

  def initialize(app)
    @app = app
  end

  def call(env)
    parts = Rack::Utils.unescape(env["PATH_INFO"]).split(SEPARATORS)
    return [403, {"Content-Type" => "text/plain"}, "Forbidden"] if parts.include? ".."
    request = Rack::Request.new(env)
    site = env['yodel.site']
    
    unless site.nil?
      public_directories = site.public_directories
    else
      public_directories = Yodel.config.public_directories
    end
    
    public_directories.each do |public_dir|
      path = File.join(public_dir, *parts)
      if File.file?(path) && File.readable?(path)
        return dup.serve_file(path, env)
      end
    end
    
    # raise any delayed exceptions. These are delayed till this middleware so
    # the assets needed to render the error pages for them are available. Without
    # this delay, a DomainNotFound exception raised in SiteDetector would prevent
    # PublicAssest from serving the css or images used on the error page.
    raise DomainNotFound.new(request.host, request.port) if site.nil?
    raise MissingRootDirectory.new(site, request.port) if !File.directory?(site.root_directory)
    @app.call(env)
  end
  
  def each
    File.open(@path, 'rb') do |file|
      file.seek(@range.begin)
      remaining_len = @range.end - @range.begin + 1
      while remaining_len > 0
        part = file.read([8192, remaining_len].min)
        break unless part
        remaining_len -= part.length
        yield part
      end
    end
  end
  
  protected
    def serve_file(path, env)
      response = [200, {
        "Last-Modified" => File.mtime(path).httpdate,
        "Content-Type"  => Rack::Mime.mime_type(File.extname(path), 'text/plain')
      }, self]
      
      size = FileTest.size?(path) || Rack::Utils.bytesize(IO.read(path))
      ranges = Rack::Utils.byte_ranges(env, size)
      
      if ranges.nil? || ranges.length > 1
        @range = 0..size-1
      elsif ranges.empty?
        return [416, {"Content-Type" => "text/plain"}, "Byte range unsatisfiable"]
      else # partial content
        @range = ranges[0]
        response[0] = 206
        response[1]["Content-Range"]  = "bytes #{@range.begin}-#{@range.end}/#{size}"
        size = @range.end - @range.begin + 1
      end
      
      response[1]["Content-Length"] = size.to_s
      @path = path
      response
    end
end
