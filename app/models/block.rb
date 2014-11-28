require 'mongoid'

class Block
  include Mongoid::Document
  include Mongoid::Enum
  field :name, type: String
  field :description, type: String
  enum :type, [:text, :number, :image, :tel, :date, :select, :list]
end
