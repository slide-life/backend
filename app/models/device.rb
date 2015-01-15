require 'mongoid'

class Device
  include Mongoid::Document
  field :registration_id
  enum :type, [:android, :iphone]
  belongs_to :user

  def push(title, data)
    case :type
      when :android
      when :iphone
        notification = Houston::Notification.new(device: registration_id)
        notification.alert = title
        notification.custom_data = data
        APN.push(notification)
    end
  end
end
