require 'mongoid'
require 'bcrypt'
require 'securerandom'
require 'twilio-ruby'

require_relative 'identifier'
require_relative '../utils/messenger'

class User < Actor
  field :password, type: String

  has_many :identifiers
  has_many :devices

  def initialize_password(password)
    self.password = BCrypt::Password.create(password)
  end

  def build_identifier(value, type)
    raise 'Invalid type.' if not IDENTIFIER_TYPES.include? type.to_sym
    raise 'Identifier has already been claimed.' if Identifier.where(value: value, _type: type).exists?

    if type.to_sym == :phone
      pin = generate_pin
      begin
        Messenger.send_verification_sms(value, pin)
      rescue Twilio::REST::RequestError
        raise 'Could not verify phone number'
      else
        return Phone.new(value: value, verification_code: pin)
      end
    else # type.to_sym == :email
      return Email.new(value: value)
    end
  end

  def as_json(params={})
    params[:include] ||= :identifiers
    puts "#{params.inspect} params"
    super(params)
  end

  private

  def generate_pin
    10**5 + SecureRandom.random_number(10**5)
  end
end
