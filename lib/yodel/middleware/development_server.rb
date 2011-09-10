require 'rack/utils'
require 'rack/mime'

# some code copied from Rack::File
class DevelopmentServer
  SEPARATORS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)
  
  def initialize
    @directories = []
    @root = nil
    detect_public_directories
  end
  
  # Response strategy: attempt to find and serve a static file before
  # any middleware or the yodel app process the request. If the file
  # is not found, fork a new yodel application to respond.
  def call(env)
    parts = Rack::Utils.unescape(env["PATH_INFO"]).split(SEPARATORS)
    return [403, {"Content-Type" => "text/plain"}, "Forbidden"] if parts.include? ".."
    
    # serve any static files
    @directories.each do |public_dir|
      path = public_dir.join(*parts)
      if path.file? && path.readable?
        return dup.serve_file(path, env)
      end
    end
    
    # pass the request to a new yodel application process
    read_fd, write_fd = IO.pipe

    # child process loads yodel and responds to the request;
    # the marshalled rack response is written over the pipe
    Process.fork do
      read_fd.close
      require 'yodel'
      status, headers, response = Application.new.call(env)
      body = []
      response.each {|chunk| body << chunk.to_s}
      payload = Marshal.dump([status, headers, body])
      write_fd.write(payload)
      write_fd.close
    end
    
    # the parent server waits until pipe EOF and unmarshals
    # the response, sending it as the result of the request
    write_fd.close
    response = read_fd.read
    read_fd.close
    Marshal.load(response)
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
    def detect_public_directories
      # interim: for now, assume the server is started from an app
      # root, and all extensions exist in the extensions folder
      @root = Pathname.new(File.dirname($settings_file))
      extensions = @root.join('extensions')
      @directories << @root.join('public')
      @directories << @root.join('uploads')
      return unless extensions.exist?
      extensions.entries.each do |extension|
        next if extension.to_s.start_with?('.')
        public_dir = extension.realpath(extensions).join('public')
        @directories << public_dir if public_dir.exist?
      end
    end
    
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
