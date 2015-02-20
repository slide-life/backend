require 'mongoid'

class Form
  include Mongoid::Document

  belongs_to :vendor

  field :name, type: String
  field :description, type: String
  field :form_fields, type: Array
end
