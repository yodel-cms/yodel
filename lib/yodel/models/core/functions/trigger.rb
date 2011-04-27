module Yodel
  class Trigger < Yodel::SiteRecord
    collection :triggers
    field :source, :string
    field :instructions, :array
    
    before_save :compile_function
    def compile_function
      self.instructions = Yodel::Function.new(source).instructions
    end
    
    def run(record)
      Yodel::Function.new(instructions).execute(record)
    end
  end
end
