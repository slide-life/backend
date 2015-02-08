require 'mongoid'

class Device
  include Mongoid::Document
  include Mongoid::Enum
  field :registration_id
  enum :type, [:android, :ios]
  belongs_to :user

  validates_presence_of :registration_id
  validates_presence_of :type
end
