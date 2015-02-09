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

  def serialize
    { id: self.id.to_json,
      left: self.left_id.to_json,
      right: self.right_id.to_json,
      left_key: self.left_key,
      right_key: self.right_key,
      conversations: self.conversations }.to_json
  end
end
