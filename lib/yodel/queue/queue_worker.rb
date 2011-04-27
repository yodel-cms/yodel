module Yodel
  class QueueWorker
    PAUSE_DURATION = 1
    def initialize(queue, stats_thread)
      @stats_thread = stats_thread
      @queue = queue
      run
    end
    
    def run
      @running = true
      @thread = Thread.new do
        while @running
          task = @queue.pop
          sleep(PAUSE_DURATION) and next if task.nil?
          task.execute
          task.destroy
          @stats_thread.processed_task
        end
      end
    end
    
    def stop
      @running = false
    end
    
    def kill
      @thread.kill
    end
    
    def join
      @thread.join
    end
  end
end
