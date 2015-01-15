require 'mongoid'

class Vendor
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  has_many :relationships
end
