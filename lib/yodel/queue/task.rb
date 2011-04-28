module Yodel
  class Task < SiteRecord
    collection :queue
    field :type, :string
    field :params, :hash
    field :due, :time
    field :created_at, :time
    field :locked, :time
    
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
        email = site.emails.find(params.delete('_id'))
        email.perform_delivery(params)
      when 'call_api'
        api_call = site.api_calls.find(params.delete('_id'))
        api_call.perform_call(params)
      end
    end
  end
end
