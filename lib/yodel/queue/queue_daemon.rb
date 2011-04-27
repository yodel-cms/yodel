module Yodel
  module QueueDaemon
    IMMEDIATE_WORKERS = 1
    DELAYED_WORKERS = 1
    
    def self.run
      immediate_queue = Yodel::Queue.new(due: nil)
      delayed_queue = Yodel::Queue.new(due: {'$ne' => nil})

      immediate_workers = []
      delayed_workers = []
      
      puts "Starting Workers..."
      stats_thread = Yodel::StatsThread.new
      IMMEDIATE_WORKERS.times do
        immediate_workers << Yodel::QueueWorker.new(immediate_queue, stats_thread)
      end

      DELAYED_WORKERS.times do
        delayed_workers << Yodel::QueueWorker.new(delayed_queue, stats_thread)
      end
      
      Signal.trap('INT') do
        puts("Shutting down...")
        stats_thread.stop
        immediate_workers.each(&:stop)
        delayed_workers.each(&:stop)
      end

      immediate_workers.each {|worker| worker.join}
      delayed_workers.each {|worker| worker.join}
      puts "Shutdown complete"
    end
  end
end
