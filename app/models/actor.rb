class Actor
  include Mongoid::Document
  field :key, type: String
  field :responses, type: Array, default: []
  has_many :endpoints, as: :entity
  has_many :upstream_conversations, class_name: "Conversation", as: :upstream
  has_many :downstream_conversations, class_name: "Conversation", as: :downstream

  def listen(ws)
    endpoint = Endpoint.new(method: :method_ws)
    endpoint.listen(ws)
    endpoint.save!

    self.endpoints << endpoint
    save!
  end

  def notify(payload)
    self.endpoints.each do |endpoint|
      endpoint.stream(:verb_post, payload)
    end
  end

  def stream(payload)
    self.responses << payload
    save!
    notify(payload.to_json)
  end
end

