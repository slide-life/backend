require 'mongoid'

class User
  include Mongoid::Document
  field :number, type: String
  field :public_key, type: String
  field :key, type: String
  field :profile, type: Hash, default: {}
  has_many :channels, inverse_of: :recipient
  has_many :devices
  has_many :relationships

  def patch!(patch)
    patch.each {|k,v|
      self.profile[k] = v
    }
    save!
  end

  def add_device(params)
    device = Device.new(registration_id: params[:registration_id],
                        device_type: params[:device_type].to_sym)
    device.save!
    self.devices << device
    save!
  end
end
