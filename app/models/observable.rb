require 'mongoid'

class Observable
  include Mongoid::Document
  has_many :endpoints, as: :entity
  has_many :upstream_conversations, class_name: "Conversation", as: :upstream_entity
  has_many :downstream_conversations, class_name: "Conversation", as: :downstream_entity
  field :key, type: String
  field :public_key, type: String

  def add_device(params)
    device = Endpoint.Device(registration_id: params[:registration_id],
                             device_type: params[:device_type].to_sym)
    device.save!
    self.endpoints << device
    save!
  end

  def listen(ws)
    endpoint = Endpoint.new_with_ws(ws)
    endpoint.save!

    self.endpoints << endpoint
    save!
  end

  def notify(verb, payload)
    self.endpoints.each do |endpoint|
      endpoint.stream(verb, payload)
    end
  end
end
