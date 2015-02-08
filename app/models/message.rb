require 'mongoid'

class Message
  include Mongoid::Document
  include Mongoid::Enum

  enum :type, [:request, :response, :deposit]
end
