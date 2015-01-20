require 'mongoid'

class VendorUserList
  field :hashed_name, type: String
  belongs_to :vendor
  has_many :vendor_users
end
