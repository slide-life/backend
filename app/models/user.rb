require 'mongoid'
require_relative 'recordable'

class User < Recordable
  field :number, type: String

  validates_presence_of :number

  def encrypted_vendor_users
    self.profile['_vendor_users'] || []
  end
end

