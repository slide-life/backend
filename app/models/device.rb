require 'mongoid'

class Device
  include Mongoid::Document
  include Mongoid::Enum
  field :registration_id
  enum :device_type, [:android, :ios]
  belongs_to :user
  belongs_to :endpoint

  def push(title, data)
    case self.device_type
      when :android
        options = { data: { type: '0', json: data.to_json }, collapse_key: 'slide_request' }
        response = GCMInstance.send([self.registration_id], options)
      when :ios
        notification = Houston::Notification.new(device: registration_id)
        notification.alert = title
        notification.custom_data = data
        APN.push(notification)
    end
  end
end
