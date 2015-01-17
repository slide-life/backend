require 'mongoid'

class User
  include Mongoid::Document
  field :number, type: String
  field :public_key, type: String
  field :key, type: String
  field :profile, type: Hash, default: {}
  has_many :channels, inverse_of: :recipient
  has_many :endpoints, as: :entity
  has_many :relationships
  has_many :upstream_conversations, class_name: "Conversation", as: :upstream_entity
  has_many :downstream_conversations, class_name: "Conversation", as: :downstream_entity

  def patch!(patch)
    patch.each {|k,v|
      self.profile[k] = v
    }
    save!
  end

  def add_device(params)
    device = Endpoint.Device(registration_id: params[:registration_id],
                             device_type: params[:device_type].to_sym)
    device.save!
    self.endpoints << device
    save!
  end

  def notify(conversation, blocks)
    self.endpoints.each do |endpoint|
      endpoint.stream(:verb_request, {
        device: endpoint.device,
        conversation: conversation,
        blocks: blocks,
        title: "New data request"})
    end
  end
end
