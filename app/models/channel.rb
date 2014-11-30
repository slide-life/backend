require_relative 'store'

class Channel < Store
  include Mongoid::Document
  field :key, type: String
  field :blocks, type: Array, default: []
  field :buckets, type: Array, default: []
  field :open, type: Boolean, default: false

  def stream(payload)
    notify(payload)
  end
end
