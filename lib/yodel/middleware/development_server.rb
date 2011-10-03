require 'rack/utils'
require 'rack/mime'

class StreamClosed < StandardError
end

class DevelopmentServer
  SEPARATORS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)
  
  class Message
    attr_accessor :status, :headers, :body, :env, :data, :message_type
    MESSAGE_TYPES = {request: 0, response: 1, restart: 2, exit: 3}
    
    def request?; @message_type == :request; end
    def response?; @message_type == :response; end
    def restart?; @message_type == :restart; end
    def exit?; @message_type == :exit; end
    
    def initialize(message_type)
      @message_type = message_type
    end
    
    def self.read(socket)
      message = Message.new(nil)
      message.message_type = MESSAGE_TYPES.keys[read_int(socket)]
      
      if message.request? || message.response?
        length = read_int(socket)
        message.data = Marshal.load(socket.read(length))
        
        if message.request?
          message.data['rack.input'] = StringIO.new(message.data['rack.input'])
          message.data['rack.errors'] = STDERR
        elsif message.response?
          message.data[2] = [message.data[2]]
        end
      end
      
      message
    end
    
    def write(socket)
      write_int(MESSAGE_TYPES[@message_type], socket)
      payload = nil
      
      if request?
        # convert input (StringIO) to a normal string, and
        # remove the reference to STDERR for transmission
        @env['rack.input'] = @env['rack.input'].read if @env['rack.input'].is_a?(StringIO)
        @env['rack.errors'] = nil
        payload = Marshal.dump(@env)
      elsif response?
        body = ''
        @body.each {|chunk| body << chunk.to_s}
        payload = Marshal.dump([@status, @headers, body])
      end
      
      if payload
        write_int(payload.length, socket)
        socket.write(payload)
      end
    end
    
    private
      def self.read_int(socket)
        int = socket.read(4)
        raise StreamClosed if int.nil?
        int.unpack('L').first
      end
      
      def write_int(int, socket)
        socket.write([int].pack('L'))
      end
  end
  
  def initialize
    spawn_server
  end
  
  def call(env)
    parts = Rack::Utils.unescape(env["PATH_INFO"]).split(SEPARATORS)
    return [403, {"Content-Type" => "text/plain"}, "Forbidden"] if parts.include? ".."
    
    # pass the request through to a yodel server. if the server
    # responds with a restart message (yodel source files have
    # changed and need to be re-loaded) spawn a new server and
    # write the request again (assume the request is successful)
    request = Message.new(:request)
    request.env = env
    request.write(@client_socket)
    response = Message.read(@client_socket)
    
    if response.restart?
      puts "Spawning new server"
      spawn_server
      request.write(@client_socket)
      response = Message.read(@client_socket)
    end
    
    # response data is a valid rack response
    response.data
  end
  
  protected
    def spawn_server
      # http requests are passed between the client (development server)
      # and the server (yodel server) over a socket pair. Pipe's aren't
      # used because the server may be forked for a long time and respond
      # to multiple requests before being reaped
      @client_socket.close unless @client_socket.nil?
      @client_socket, @server_socket = UNIXSocket.pair
      
      # child process loads yodel and responds to the request; if any
      # source files have been modified since the server was started, send
      # a restart message to the client and exit
      pid = Process.fork
      if pid.nil?
        @client_socket.close
        require File.join(File.dirname(__FILE__), '..', '..', 'yodel')
        closed = false
        
        @application = Application.new
        @modification_times = $LOADED_FEATURES.each_with_object({}) do |path, mtimes|
          mtimes[path] = File.mtime(path) if File.exist?(path)
        end
        
        loop do
          # block until a new request is received
          request = Message.read(@server_socket)
          
          # check for modified files
          @modification_times.each do |path, modified_time|
            if File.exist?(path) && File.mtime(path) > modified_time
              message = Message.new(:restart)
              message.write(@server_socket)
              @server_socket.close
              closed = true
              break
            end
          end
          
          # kill the server if a file was changed
          break if closed
          
          # otherwise respond to the request
          if request.request?
            response = Message.new(:response)
            response.status, response.headers, response.body = @application.call(request.data)
            response.write(@server_socket)
          end
        end
      
      else
        Process.detach(pid)
        @server_socket.close
      end
    end
end
