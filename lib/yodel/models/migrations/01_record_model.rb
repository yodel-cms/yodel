class RecordModelMigration < Yodel::Migration
  def self.up(site)
    site.models.create_model('Record') do |model|
      model.add_field :show_in_search, Boolean, default: true, section: 'Options'
      model.add_field :search_keywords, Array, default: [], display: false
      model.add_field :search_title, Function, fn: 'name'
      model.add_field :name, Function, fn: '"#{model.name} (##{_id.to_s})"'
    end
  end
  
  def self.down(site)
    site.records.destroy
  end
end
