class Actor
  include Mongoid::Document
  field :key, type: String
  field :responses, type: Array, default: []
  has_many :endpoints

  def listen(ws)
    endpoint = Endpoint.new(method: :ws)
    endpoint.listen(ws)
    endpoint.save!

    self.endpoints << endpoint
    save!
  end

  def notify(payload)
    self.endpoints.each do |endpoint|
      endpoint.notify(payload)
    end
  end

  def stream(payload)
    self.responses << payload
    save!
    notify(payload.to_json)
  end
end

