require 'mongoid'
require_relative 'recordable'

class User < Recordable
  field :number, type: String
  has_many :relationships

  validates_presence_of :number
end

