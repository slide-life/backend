require 'mongoid'
require_relative 'securable'

class Recordable < Securable
  field :profile, type: Hash, default: {}
  field :checksum, type: String

  after_create :add_patch_listener

  def patch!(patch)
    self.profile = self.profile.deep_merge(patch)
    save!
  end

  def check_checksum(chk)
    self.checksum == chk
  end

  protected
  def add_patch_listener
    patch_listener = Proc.new do |payload|
      if payload['patch']
        payload_patch = payload['patch']
        self.patch!(payload_patch)
      end
    end

    endpoint = Endpoint.new_with_proc(patch_listener)
    endpoint.save!

    self.endpoints << endpoint
  end
end
