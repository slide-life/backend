require 'mongoid'

class VendorForm
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  field :form_fields, type: Array
  belongs_to :vendor

  def responses
    self.vendor.get_responses(self.form_fields)
  end
end
