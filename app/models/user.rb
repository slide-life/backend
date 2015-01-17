require 'mongoid'
require_relative 'observable'

class User < Observable
  field :number, type: String
  field :public_key, type: String
  field :profile, type: Hash, default: {}
  has_many :channels, inverse_of: :recipient
  has_many :relationships

  def patch!(patch)
    patch.each {|k,v|
      self.profile[k] = v
    }
    save!
  end

  def listen(ws)
    endpoint = Endpoint.new(method: :method_ws)
    endpoint.listen(ws)
    endpoint.save!

    self.endpoints << endpoint
    save!
  end
end

