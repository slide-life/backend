require 'twilio-ruby'

module Messenger
  @twilio= Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])

  def self.send_verification_sms(to, pin)
    @twilio.account.messages.create({ from: ENV['TWILIO_PHONE_NUMBER'], to: to, body: "Your slide verification code is #{pin}. It will expire in 5 minutes." })
  end
end
