require 'mongoid'

class User
  include Mongoid::Document
  field :number, type: String
  field :public_key, type: String
  field :devices, type: Array, default: []
  has_many :channels, :inverse_of => :recipient
end
