require 'mongoid'

class VendorUserList
  include Mongoid::Document
  field :hashed_name, type: String
  belongs_to :vendor
  has_many :vendor_users

  validates_presence_of :hashed_name
end
