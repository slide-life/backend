require 'mongoid'
require_relative 'observable'

class Securable < Observable
  field :key, type: String
  field :public_key, type: String
end
