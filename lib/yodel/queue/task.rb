module Yodel
  class Task < SiteRecord
    FAILED_TASK_DELAY = 2 * 60  # 2 minutes
    MAX_TASK_ATTEMPTS = 5
    
    collection :queue
    field :type, :string
    field :params, :hash
    field :due, :time
    field :created_at, :time
    field :locked, :time
    field :repeat_in, :integer
    field :attempts, :integer, default: 0
    field :stack_trace, :string
    
    def self.add_task(type, params, site, due=nil)
      task = Yodel::Task.new(site)
      task.type = type.to_s
      task.params = params
      task.due = due
      task.save
    end
    
    def execute
      case self.type
      when 'deliver_email'
        email = site.emails.find(params['_id'])
        email.perform_delivery(params)
      when 'call_api'
        api_call = site.api_calls.find(params['_id'])
        api_call.perform_call(params)
      when 'perform_destroy_stale_carts'
        Yodel::Cart.perform_destroy_stale_carts(site)
      end
      
      # if the task repeats, place it on the queue again by reseting the
      # due time and removing the locked time making it available again
      if repeat_in?
        self.due = Time.at(Time.now.utc.to_i + repeat_in)
        self.locked = nil
        self.save
      else
        self.destroy
      end
      
    rescue
      # increase the attempt count after any exceptions. after N attempts
      # the task is halted and assumed to have failed. manual intervention
      # is required to start it again. delay its execution on the queue for
      # a certain amount of time to potentially allow resource issues to
      # "fix themselves" (such as loss of network).
      self.attempts += 1
      
      if self.attempts < MAX_TASK_ATTEMPTS
        self.due = Time.at(Time.now.utc.to_i + FAILED_TASK_DELAY)
        self.locked = nil
      end
      
      self.stack_trace = "Error: #{$!}\n#{$@.join("\n")}"
      self.save
    end
  end
end
