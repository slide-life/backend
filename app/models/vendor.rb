require 'mongoid'
require_relative 'recordable'

class Vendor < Recordable
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  field :invite_code, type: String
  field :checksum, type: String
  has_many :relationships
  has_many :vendor_forms

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
