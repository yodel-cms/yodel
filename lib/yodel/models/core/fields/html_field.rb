module Yodel
  class HTMLField < TextField
    def search_terms_set(html)
      super(to_text(html))
    end

    def to_text(html)
      Hpricot(html.to_s).search('//text()').collect(&:to_s).collect(&:strip).join(' ').strip
    end
  end
end
