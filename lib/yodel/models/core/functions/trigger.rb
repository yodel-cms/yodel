class Trigger < SiteRecord
  collection :triggers
  field :source, :string
  field :instructions, :array
  
  before_save :compile_function
  def compile_function
    self.instructions = Function.new(source).instructions
  end
  
  def run(record)
    Function.new(instructions).execute(record)
  end
end
