require 'mongoid'
require_relative 'recordable'

class VendorUser < Recordable
  field :uuid, type: String
  belongs_to :vendor
  belongs_to :vendor_user_list

  validates_presence_of :uuid, on: :create

  before_create :initialize_uuid

  protected
  def initialize_uuid
    self.uuid = (0...32).map{65.+(rand(25)).chr}.join
  end
end