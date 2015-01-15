require 'mongoid'

class User
  include Mongoid::Document
  field :number, type: String
  field :public_key, type: String
  has_many :channels, inverse_of: :recipient
  has_many :devices
  has_many :relationships

  def add_device(params)
    device = Device.new(registration_id: params['registration_id'],
                        type: params['type'].to_sym)
    device.save!
    self.devices << device
    save!
  end
end
