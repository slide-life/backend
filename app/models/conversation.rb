require 'mongoid'

class Conversation
  include Mongoid::Document

  belongs_to :relationship
  field :name, type: String

  validates_presence_of :name
end
