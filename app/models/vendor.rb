require 'mongoid'

require_relative 'actor'

class Vendor < Actor
  field :name, type: String
  field :domain, type: String
  field :api_key, type: String
  # has profile.public
  # has_one :schema
end
