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
        email = site.emails.find(params.delete('id'))
        email.perform_delivery(params)
      end
    end
  end
end
