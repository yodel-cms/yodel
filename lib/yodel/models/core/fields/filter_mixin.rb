module Yodel
  module FilterMixin
    def typecast(value, record)
      Hpricot(value.to_s).search('text()').collect(&:to_s).collect(&:strip).join(' ').strip
    end

    def untypecast(value, record)
      value.to_s
    end
  end
end
