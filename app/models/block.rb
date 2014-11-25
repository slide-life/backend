require 'mongoid'

class Block
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  field :typeName, type: String
  field :typeId, type: String
end
