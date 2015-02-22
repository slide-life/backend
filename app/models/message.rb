require 'mongoid'

MESSAGE_TYPES = [:request, :response, :deposit]

class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Enum

  enum :to, [:left, :right]

  belongs_to :conversation

  default_scope -> { order_by(created_at: :asc) }
  scope :by_relationship, -> (relationship) {
    where(:conversation_id.in => relationship.conversations.pluck(:id))
  }
  scope :has_fields, -> { where(:_type.in => ['Response', 'Deposit']) }

  def self.merge_with_components(fields, messages)
    fields_filter = if fields
                      -> (a) { fields.include? a }
                    else
                      -> (_) { true }
                    end
    ret = {}
    messages.each do |message|
      message.data.keys.select(&fields_filter).each do |k|
        ret[k] = message.data[k]
      end
    end

    ret
  end

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
  field :read, type: Boolean, default: false
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
