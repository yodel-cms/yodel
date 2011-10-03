require 'rubydns'

class DNSServer
  def self.start
    @resolv = Resolv::DNS.new
    RubyDNS::run_server(:listen => [[:udp, "0.0.0.0", 2827], [:tcp, "0.0.0.0", 2827]]) do
      match(/yodel/) do |match_data, transaction|
        transaction.respond!("127.0.0.1")
      end

      otherwise do |transaction|
        transaction.passthrough!(@resolv)
      end
    end
  end
end
