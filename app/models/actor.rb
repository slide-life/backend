require 'mongoid'

class Actor
  include Mongoid::Document

  field :key

  validates_presence_of :key
end
