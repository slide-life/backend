require_relative 'store'

class Channel < Store
  include Mongoid::Document
  field :key, type: String
  field :blocks, type: Array, default: []
  field :buckets, type: Array, default: []
  field :open, type: Boolean, default: true

  def stream(payload)
    self.buckets << payload
    save!
    notify(payload)
  end
end
