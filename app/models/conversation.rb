class Conversation
  include Mongoid::Document
  field :key, type: String
  field :upstreams, type: Array, default: []
  field :downstreams, type: Array, default: []
  field :name, type: String
  field :description, type: String
  belongs_to :upstream, polymorphic: true 
  belongs_to :downstream, polymorphic: true 

  validates_presence_of :key
  validates_associated :upstream
  validates_associated :downstream

  def upstream!(payload)
    self.upstreams << payload
    save!
    upstream.stream(payload)
    to_json
  end

  def request_content!(user, blocks)
    # TODO: self needs to carry along downstream/upstream number
    user.notify(:verb_request, {
      conversation: self, blocks: blocks
    })
  end

  def deposit_content!(user, fields)
    user.notify(:verb_post, {
      conversation: self, fields: fields
    })
  end

  def serialize
    params = {}
    params[:include] = {}
    params[:include][:downstream] = { only: [:number] } if self.downstream.is_a? User
    params[:include][:upstream] = { only: [:number] } if self.upstream.is_a? User

    self.to_json params
  end
end

