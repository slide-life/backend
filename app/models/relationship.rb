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

  scope :of_actor, -> (actor) { self.or({ left: actor }, { right: actor }) }
  scope :between, -> (one, two) {
    self.or(
      { left: one, right: two },
      { left: two, right: one }
    )
  }

  def key_for(actor)
    return {
      self.left_id => self.left_key,
      self.right_id => self.right_key
    }[actor.id]
  end

  def counterparty_of(actor)
    return {
      self.left_id => self.right,
      self.right_id => self.left
    }[actor.id]
  end

  def serialize
    { id: self.id.to_s,
      left: self.left_id.to_s,
      right: self.right_id.to_s,
      left_key: self.left_key,
      right_key: self.right_key,
      conversations: self.conversations }.to_json
  end
end
