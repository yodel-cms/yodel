require 'highline'

module Feedback
  def self.report(verb, noun)
    @h ||= HighLine.new
    @h.say "<%= color('#{verb}', GREEN) %>\t#{noun}"
  end
end
