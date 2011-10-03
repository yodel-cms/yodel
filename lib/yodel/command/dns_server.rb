require 'rubydns'

class DNSServer
  def self.start
    @resolv = Resolv::DNS.new
    RubyDNS::run_server(:listen => [[:udp, "0.0.0.0", Yodel.config.dns_port], [:tcp, "0.0.0.0", Yodel.config.dns_port]]) do
      match(/yodel/) do |match_data, transaction|
        transaction.respond!("127.0.0.1")
      end

      otherwise do |transaction|
        transaction.passthrough!(@resolv)
      end
    end
  end
end
