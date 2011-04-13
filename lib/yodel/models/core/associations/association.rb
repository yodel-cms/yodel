module Yodel
  class Association < Field    
    def validate(value, record, errors)
      true
    end
    
    def json_action(action, value, record)
      store = record.get_raw(name)
      
      case action
      when 'set'
        clear(store, record)
        process_json_items(value, record, store, :associate)
      when 'add'
        process_json_items(value, record, store, :associate)
      when 'remove'
        process_json_items(value, record, store, :unassociate)
      when 'clear'
        clear(store, record)
      end
    end
    
    def from_json(value, record)
      store = record.get_raw(name)
      clear(store, record)
      process_json_items(value, record, store, :associate)
    end
    
    
    private
      def process_json_items(items, record, store, method)
        items = [items] unless items.respond_to?(:each)
        items.each do |raw_item|
          item = process_json_item(raw_item, store, record)
          next if item.nil?
          send(method, item, store, record)
        end
      end
  end
end
