require 'mongoid'

class User
  include Mongoid::Document
  field :username, type: String
  field :devices, type: Array, default: []
end
