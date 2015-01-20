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
end
