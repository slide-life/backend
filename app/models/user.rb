require 'mongoid'

class User
  include Mongoid::Document
  field :number, type: String
  field :devices, type: Array, default: []
end
