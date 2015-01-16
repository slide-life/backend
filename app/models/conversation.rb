class Conversation
  include Mongoid::Document
  field :upstream, type: String
  field :downstream, type: String
  field :key, type: String
  field :upstreams, type: Array, default: []
  field :downstreams, type: Array, default: []
  field :name, type: String
  field :description, type: String

  def upstream!(payload)
    self.upstreams << payload
    save!
    # NB: assumes actor
    upstream = Actor.find(self.upstream)
    upstream.stream(payload)
    to_json
  end
end

