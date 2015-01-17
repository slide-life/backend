require 'mongoid'

class Block
  include Mongoid::Document
  field :organization, type: String
  field :schema, type: Object
end
