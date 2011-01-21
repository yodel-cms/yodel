module Yodel
  class RawLayout < Layout
    def render_with_controller(controller, extra_context = {})
      extra_context[:content] || ''
    end
  end
end
