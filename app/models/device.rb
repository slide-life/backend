require 'mongoid'

class Device < Listener
  field :registration_id

  belongs_to :user

  validates_presence_of :registration_id
end

class AndroidDevice < Device
  def send_data(data)
    options = { data: { type: '0', json: data }, collapse_key: 'slide_request' }
    response = GCMInstance.send([self.registration_id], options)
  end
end

class AppleDevice < Device
  def send_data(data)
    notification = Houston::Notification.new(device: registration_id)
    notification.custom_data = data
    APN.push(notification)
  end
end
