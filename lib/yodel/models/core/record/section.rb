class Section < Array
  attr_reader :name
  
  def initialize(name, initial_fields=[])
    super()
    @name = name
    push(*initial_fields)
  end
  
  def display?
    any? {|field| display_field?(field)}
  end
  
  def displayed_fields
    select {|field| display_field?(field)}
  end
  
  private
    def display_field?(field)
      field.display? && field.default_input_type.present?
    end
end
