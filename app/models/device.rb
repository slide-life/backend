require 'mongoid'

class Device < Listener
  field :registration_id

  belongs_to :user

  validates_presence_of :registration_id

  def notify(event)
    self.push(event.conversation.name, event) #TODO: push just the event?
  end
end

class AndroidDevice < Device
  def push(title, data)
    options = { data: { type: '0', json: data.to_json }, collapse_key: 'slide_request' }
    response = GCMInstance.send([self.registration_id], options)
  end
end

class AppleDevice < Device
  def push(title, data)
    notification = Houston::Notification.new(device: registration_id)
    notification.alert = title
    notification.custom_data = data #TODO: to_json needed here?
    APN.push(notification)
  end
end
