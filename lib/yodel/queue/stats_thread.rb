module Yodel
  class StatsThread
    PERIOD = 60
    
    def initialize
      @processed = 0
      @running = true
      Thread.new do
        while @running
          sleep(PERIOD)
          puts "Processed #{@processed} tasks"
          @processed = 0
        end
      end
    end
    
    def stop
      @running = false
    end
    
    def kill
      @thread.kill
    end
    
    def processed_task
      @processed += 1
    end
  end
end
