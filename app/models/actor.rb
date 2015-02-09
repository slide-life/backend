require 'mongoid'
require_relative './listener'

class Actor
  include Mongoid::Document

  field :key
  embeds_one :profile

  has_many :listeners

  validates_presence_of :key

  def listen!(ws)
    listener = Websocket.build_socket_listener(ws)
    self.listeners << listener
    save!

    listener
  end

  def unlisten!(listener)
    self.listeners.delete listener
    save!
  end

  def notify(event)
    self.listeners.select do |listener|
      listener.scoped_to?(event)
    end.each do |listener|
      listener.notify(event)
    end
  end
end

class Profile
  include Mongoid::Document

  field :private, type: Hash, default: {}
  field :public, type: Hash, default: {}

  embedded_in :actor

  def patch(profile)
    self.private = merge_profiles(self.private, profile['private']) if profile['private']
    self.public  = merge_profiles(self.public, profile['public']) if profile['public']
  end

  private

  def merge_profiles(profile, patch)
    merger = proc { |_, original, update| Hash === original && Hash === update ? original.merge(update, &merger) : update }
    profile.merge(patch, &merger)
  end
end
