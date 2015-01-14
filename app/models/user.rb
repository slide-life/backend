require 'mongoid'

class User
  include Mongoid::Document
  field :number, type: String
  field :public_key, type: String
  field :key, type: String
  field :devices, type: Array, default: []
  field :profile, type: Hash, default: {}
  has_many :channels, :inverse_of => :recipient

  def patch!(patch)
    patch.each {|k,v|
      self.profile[k] = v
    }
    save!
  end
end
