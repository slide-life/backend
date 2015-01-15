require 'mongoid'

class Relationship
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  belongs_to :vendor
  belongs_to :user, foreign_key: 'number'
end
