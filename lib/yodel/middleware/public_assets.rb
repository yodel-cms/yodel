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
    site = env['yodel.site']
    
    if site
      public_directories = site.public_directories
    else
      public_directories = Yodel.config.public_directories
    end
    
    public_directories.each do |public_dir|
      path = public_dir.join(*parts)
      if path.file? && path.readable?
        return dup.serve_file(path, env)
      end
    end
    
    @app.call(env)
  end
  
  def each
    @path.open('rb') do |file|
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
        "Last-Modified" => path.mtime.httpdate,
        "Content-Type"  => Rack::Mime.mime_type(path.extname, 'text/plain')
      }, self]
      
      size = path.size? || Rack::Utils.bytesize(path.read)
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
