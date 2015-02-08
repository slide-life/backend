require 'mongoid'
require 'bcrypt'

require_relative 'actor'
require_relative 'identifier'

class User < Actor
  field :password, type: String

  has_many :identifiers
  # has profile.private
  # has_many :devices

  def initializePassword(password)
    self.password = BCrypt::Password.create(password)
  end

  def addIdentifier(value, type)
    if not IDENTIFIER_TYPES.include? type
      raise 'Invalid type'
    elsif Identifier.where(value: value, type: type).exists?
      raise 'Identifier has already been claimed'
    else
      self.identifiers << Identifier.new(value: value, type: type)
    end
  end
end
