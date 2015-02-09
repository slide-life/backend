require 'mongoid'

IDENTIFIER_TYPES = [:phone, :email]
PHONE_VERIFICATION_TIME_LIMIT = 5*24*60*60

class Identifier
  include Mongoid::Document

  belongs_to :user

  field :value, type: String
  field :verified, type: Boolean, default: false
  field :verification_code, type: String
end

class Phone < Identifier
  field :created, type: Time, default: Time.now
  field :attempts, type: Integer
end

class Email < Identifier
end
