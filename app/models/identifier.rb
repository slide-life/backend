require 'mongoid'

IDENTIFIER_TYPES = [:phone, :email]

class Identifier
  include Mongoid::Document
  include Mongoid::Enum

  belongs_to :user

  field :value, type: String
  field :verified, type: Boolean, default: false
end

class Phone < Identifier
end

class Email < Identifier
end
