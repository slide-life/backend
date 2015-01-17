require 'mongoid'

class Endpoint
  include Mongoid::Document
  include Mongoid::Enum
  field :url, type: String
  enum :method, [:method_ws, :method_post, :method_put, :method_proc, :method_device]
  belongs_to :entity, polymorphic: true
  has_one :device

  @@Sockets = {}
  @@Procs = {}

  module NotificationJob
    @queue = :default

    def self.perform(device, title, params)
      device.push(title, params)
    end
  end

  def self.Device(device)
    endpoint = Endpoint.new(method: :method_device)
    endpoint.device = Device.new(device)
    endpoint.device.save!
    return endpoint
  end

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def listen_with_proc(p)
    @@Procs[self._id] = p
  end

  def stream(verb, payload)
    case self.method
      when :method_ws
        if verb == :verb_post
          socket = @@Sockets[self._id]
          socket.send(payload) if socket
        end
      when :method_proc
        if verb == :verb_post
          p = @@Procs[self._id]
          p.call(payload) if p
        end
      when :method_device
        if verb == :verb_request
          NotificationJob.perform(
            self.device,
            "New data request",
            { conversation: payload[:conversation],
              blocks: payload[:blocks],
              verb: verb })
        else
          NotificationJob.perform(
            self.device,
            "New data deposit",
            { conversation: payload[:conversation],
              verb: verb,
              fields: payload[:fields] })
        end
      else
        #do nothing
    end
  end
end
