require_relative 'observable'
class Actor < Observable
  field :responses, type: Array, default: []

  def listen(ws)
    endpoint = Endpoint.new(method: :method_ws)
    endpoint.listen(ws)
    endpoint.save!

    self.endpoints << endpoint
    save!
  end

  def stream(payload)
    self.responses << payload
    save!
    notify(:verb_post, payload)
  end
end

