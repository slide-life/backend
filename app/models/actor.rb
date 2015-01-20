require 'mongoid'
require_relative 'securable'

class Actor < Securable
  field :responses, type: Array, default: []

  def stream(payload)
    self.responses << payload
    save!
    notify(:verb_post, payload)
  end
end

