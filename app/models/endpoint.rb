require 'mongoid'
require 'net/http'
require 'uri'

class Endpoint
  include Mongoid::Document
  include Mongoid::Enum
  field :url, type: String
  enum :method, [:method_ws,
                 :method_post,
                 :method_put,
                 :method_patch,
                 :method_proc,
                 :method_device]
  belongs_to :entity, polymorphic: true
  has_one :device

  validates_presence_of :method

  after_create :initialize_payload_proc

  @@Sockets = {}
  @@Procs = {}
  @@PayloadProcs = {}

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

  def self.new_with_ws(ws)
    ret = self.new(method: :method_ws)
    ret.listen(ws)
    ret
  end

  def self.new_with_proc(p)
    ret = self.new(method: :method_proc)
    ret.listen_with_proc(p)
    ret
  end

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def listen_with_proc(p)
    @@Procs[self._id] = p
  end

  def process_payload_with_proc(p)
    @@PayloadProcs[self._id] = p
  end

  def stream(verb, p)
    payload = @@PayloadProcs[self._id].call(p)
    case self.method
      when :method_ws
        socket = @@Sockets[self._id]
        socket.send({verb: verb, payload: payload}.to_json) if socket
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
      when :method_post, :method_put, :method_patch
        uri = URI.parse(url)
        request = {
          method_post: Net::HTTP::Post,
          method_put: Net::HTTP::Put,
          method_patch: Net::HTTP::Patch
        }[self.method].new(uri.request_uri)
        request["Content-Type"] = "application/json"
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.request(request)
      else
        #TODO: :method_put, :method_post, :method_patch
        #do nothing
    end
  end

  protected
  def initialize_payload_proc
    @@PayloadProcs[self._id] = Proc.new { |p| p }
  end
end
