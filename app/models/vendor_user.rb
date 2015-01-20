require 'mongoid'
require_relative 'recordable'

class VendorUser < Recordable
  field :hashed_name, type: String
  belongs_to :vendor
  belongs_to :vendor_user_list
end
