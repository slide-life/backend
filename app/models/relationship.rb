require 'mongoid'

class Relationship
  include Mongoid::Document

  has_many :conversations

  belongs_to :left, :class_name => 'Actor', :inverse_of => nil
  belongs_to :right, :class_name => 'Actor', :inverse_of => nil

  field :left_key, type: String
  field :right_key, type: String

  validates_presence_of :left
  validates_presence_of :right
end
