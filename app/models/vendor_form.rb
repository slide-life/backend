require 'mongoid'

class VendorForm < Observable
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  field :form_fields, type: Array
  belongs_to :vendor

  validates_presence_of :name
  validates_presence_of :form_fields

  validates_uniqueness_of :name

  after_create :add_patch_callbacks

  def responses
    self.vendor.get_responses(self.form_fields)
  end

  protected
  def add_patch_callbacks
    [
      Proc.new do |payload|
        #user callback

        user_id = payload['patch'].keys.first
        vendor_user = VendorUser.find(uuid: user_id)
        vendor_user.patch!(payload['patch'][user_id])
      end, Proc.new do |payload|
        #vendor callback

        user_id = payload['patch'].keys.first
        user_patch = payload['patch'][user_id]
        self.vendor.patch_response!({
          user_id => {
            '_latest_profile' => user_patch,
            self.name => user_patch
          }
        })
      end
    ].each do |proc|
      endpoint = Endpoint.new_with_proc(proc)
      self.endpoints << endpoint
    end

    save!
  end
end
