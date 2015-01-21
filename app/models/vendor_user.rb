require 'mongoid'
require_relative 'recordable'

class VendorUser < Recordable
  field :uuid, type: String
  belongs_to :vendor
  belongs_to :vendor_user_list

  validates_presence_of :uuid, on: :create

  def vendor_profile
    self.vendor.profile_for(self.uuid)
  end

  def vendor_latest_profile
    self.vendor.latest_profile_for(self.uuid)
  end

  def vendor_forms
    self.vendor.vendor_forms
  end
end
