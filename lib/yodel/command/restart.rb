require './feedback'

class Restart
  def self.can_restart?
    `uname -a` =~ /Darwin/
  end
  
  def self.restart!
    Feedback.report('starting', 'dns server')
    if `sudo launchctl list` =~ /\d+.+com.yodelcms.dns$/
      `sudo launchctl unload /Library/LaunchDaemons/com.yodelcms.dns.plist`
    end
    `sudo launchctl load /Library/LaunchDaemons/com.yodelcms.dns.plist`
    
    Feedback.report('starting', 'web server')
    if `sudo launchctl list` =~ /\d+.+com.yodelcms.server$/
      `sudo launchctl unload /Library/LaunchDaemons/com.yodelcms.server.plist`
    end
    `sudo launchctl load /Library/LaunchDaemons/com.yodelcms.server.plist`
  end
end
