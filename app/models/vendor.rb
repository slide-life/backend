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

  def stored_responses
    self.profile['_responses']
  end

  def patch_key!(vendor_user, user_key, vendor_key)
    self.patch!({
      '_keys' => { vendor_user.uuid => user_key },
      '_vendor_keys' => { vendor_user.uuid => vendor_key }
    })
  end

  def patch_response!(hash)
    self.patch!({ '_responses' => hash })
  end

  def profile_for(vendor_user_uuid)
    self.stored_responses[vendor_user_uuid]
  end

  def latest_profile_for(vendor_user_uuid)
    self.profile_for(vendor_user_uuid)['_latest_profile']
  end

  def get_responses(vendor_form)
    Hash[
      self.stored_responses.map do |user, dict|
        [user, dict[vendor_form.name]]
      end
    ]
  end

  def get_profiles(form_fields)
    Hash[
      self.stored_responses.map do |user, dict|
        user_dict = dict['_latest_profile']
        [user, Hash[
          [['_key', self.profile['_keys'][user]]] +
          form_fields.
            select { |f| ! user_dict[f].nil? }.
            map { |field| [
              field, user_dict[field]
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
