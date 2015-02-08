require 'mongoid'

MESSAGE_TYPES = [:request, :response, :deposit]

class Message
  include Mongoid::Document
  include Mongoid::Enum

  enum :to, [:left, :right]

  belongs_to :conversation
end

class Request < Message
  field :blocks, type: Array
  has_one :response
end

class Response < Message
  field :data
  belongs_to :request
end

class Deposit < Message
  field :data
end
