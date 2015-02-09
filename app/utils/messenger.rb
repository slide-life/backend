require 'nexmo'

module Messenger
  @nexmo = Nexmo::Client.new(key: ENV['NEXMO_API_KEY'], secret: ENV['NEXMO_API_SECRET'])

  def self.send_verification_sms(to, pin)
    @nexmo.send_2fa_message({ to: to, pin: pin })
  end
end
