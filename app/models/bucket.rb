require 'mongoid'

require_relative 'store'

class Bucket < Store
  include Mongoid::Document
  field :key, type: String
  field :blocks, type: Array, default: []
  field :payload, type: String

  def populate(payload)
    payload = payload
    save!
  end
end
