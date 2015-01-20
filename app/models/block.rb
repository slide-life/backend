require 'mongoid'

class Block
  include Mongoid::Document
  field :organization, type: String
  field :schema, type: Object

  validates_presence_of :organization
  validates_presence_of :schema
end
