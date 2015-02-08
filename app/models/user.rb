require 'mongoid'
require 'bcrypt'

require_relative 'identifier'

class User < Actor
  field :password, type: String

  has_many :identifiers
  has_many :devices

  def initialize_password(password)
    self.password = BCrypt::Password.create(password)
  end

  def add_identifier(value, type)
    raise 'Invalid type.' if not IDENTIFIER_TYPES.include? type.to_sym
    raise 'Identifier has already been claimed.' if Identifier.where(value: value, _type: type).exists?

    if type.to_sym == :phone
      self.identifiers << Phone.new(value: value)
    else # type.to_sym == :email
      self.identifiers << Email.new(value: value)
    end
  end
end
