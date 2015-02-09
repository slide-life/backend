require 'mongoid'

MESSAGE_TYPES = [:request, :response, :deposit]

class Message
  include Mongoid::Document
  include Mongoid::Enum

  enum :to, [:left, :right]

  belongs_to :conversation

  def as_json(params={})
    params[:methods] ||= [:message_type]
    super(params)
  end

  def as_event
    conversation = self.conversation
    relationship = conversation.relationship
    return {
      'conversation' => conversation,
      'relationship' => relationship,
      'message' => self
    }
  end
end

class Request < Message
  field :blocks, type: Array
  has_one :response

  def message_type
    :request
  end
end

class Response < Message
  field :data
  belongs_to :request

  def message_type
    :response
  end
end

class Deposit < Message
  field :data

  def message_type
    :deposit
  end
end
