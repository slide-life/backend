require 'mongoid'
require_relative 'recordable'

class Vendor < Recordable
  field :name, type: String
  field :description, type: String
  field :invite_code, type: String
  has_many :relationships
  has_many :vendor_forms
  has_many :vendor_users
  has_many :vendor_user_lists #TODO: get routes working for this

  validates_presence_of :name
  validates_presence_of :invite_code

  before_create :initialize_invite_code

  def check_invite_code(ic)
    self.invite_code == ic
  end

  def check_checksum(chk)
    self.checksum == chk
  end

  def get_responses(form_fields)
    Hash[
      self.profile['_responses'].map do |user, dict|
        [user, Hash[
          [['_key', self.profile['_keys'][user]]] +
          form_fields.
            select { |f| ! dict[f].nil? }.
            map { |field| [
              field, dict[field]
            ]}
        ]]
      end
    ]
  end

  protected
  def initialize_invite_code
    self.invite_code = (0...16).map{65.+(rand(25)).chr}.join
  end
end
