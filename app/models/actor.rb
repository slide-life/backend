require_relative 'observable'
class Actor < Observable
  field :responses, type: Array, default: []

  def stream(payload)
    self.responses << payload
    save!
    notify(:verb_post, payload)
  end
end

