class Menu < Record
  def render(page)
    if include_all_children
      items = root.children.collect do |child|
        exception = exceptions.find {|except| except.page == child}
        next if exception && !exception.show
        render_item(child, page, 0, exception ? exception.depth : depth)
      end
    else
      items = exceptions.all.collect do |exception|
        render_item(exception.page, page, 0, exception.depth)
      end
    end
    
    if include_root
      items.unshift(render_item(root, page, 0, 0))
    end
    
    "<nav>#{items.join}</nav>"
  end
  
  private
    def render_item(item, page, current_depth, max_depth)
      items = ["<a href='#{item.path}' class='#{'selected' if item == page}'>#{item.title}</a>"]
      if current_depth < max_depth
        item.children.each do |child|
          items << render_item(child, page, current_depth + 1, max_depth)
        end
      end
      items.join
    end
end
