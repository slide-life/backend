require 'mongoid'

require_relative 'store'

class Bucket < Store
  include Mongoid::Document
  field :key, type: String
  field :blocks, type: Array, default: []
  field :payload, type: Array, default: []

  def populate(payload)
    self.payload << payload
    save!
    notify(payload)
  end
end
