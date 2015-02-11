require 'mongoid'

class Vendor < Actor
  field :name, type: String
  field :domain, type: String
  field :api_key, type: String
  field :schema, type: Hash
end
