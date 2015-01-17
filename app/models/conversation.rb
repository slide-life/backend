class Conversation
  include Mongoid::Document
  field :key, type: String
  field :upstreams, type: Array, default: []
  field :downstreams, type: Array, default: []
  field :name, type: String
  field :description, type: String
  belongs_to :upstream, polymorphic: true 
  belongs_to :downstream, polymorphic: true 

  def upstream!(payload)
    self.upstreams << payload
    save!
    upstream.stream(payload)
    to_json
  end

  def request_content!(user, blocks)
    user.notify(:verb_request, {
      conversation: self, blocks: blocks
    })
  end
end

