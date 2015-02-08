require 'mongoid'

class Vendor < Actor
  field :name, type: String
  field :domain, type: String
  field :api_key, type: String
  # has_one :schema
end
