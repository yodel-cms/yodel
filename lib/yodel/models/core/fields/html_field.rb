class HTMLField < TextField
  def search_terms_set(record)
    to_text(record.get(name)).gsub(/\W+/, ' ').split
  end

  def to_text(html)
    Hpricot(html.to_s).search('//text()').collect(&:to_s).collect(&:strip).join(' ').strip
  end
end

Field::TYPES['html'] = HTMLField
