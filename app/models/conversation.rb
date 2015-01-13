class Conversation
  include Mongoid::Document
  field :upstream, type: String
  field :downstream, type: String
  field :key, type: String
  field :upstreams, type: Array, default: []
  field :downstreams, type: Array, default: []
end

