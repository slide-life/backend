require 'mongoid'
require 'net/http'
require 'uri'

LISTENER_TYPES = [:webhook, :websocket, :device]

class Listener
  include Mongoid::Document
  include Mongoid::Enum

  field :relationship_id, type: String
  field :conversation_id, type: String
  enum :message_filter, [:none, :request, :response, :deposit]

  belongs_to :actor

  def scoped_to?(event)
    return false if self.relationship_id && event['relationship'].id != self.relationship_id
    return false if self.conversation_id && event['conversation'].id != self.conversation_id
    return false if self.message_filter != :none && event['message'].message_type != self.message_filter
    true
  end
end

class Webhook < Listener
  include Mongoid::Enum

  field :url
  enum :method, [:put, :post, :patch]

  validates_presence_of :url
  validates_presence_of :method

  def notify(event)
    uri = URI.parse(self.url)
    request_kinds = {
      post: Net::HTTP::Post,
      put: Net::HTTP::Put,
      patch: Net::HTTP::Patch
    }
    request = request_kinds[self.method].new(uri.request_uri)
    request.body = event.to_json
    request["Content-Type"] = "application/json"
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request(request)
  end
end

class Websocket < Listener
  @@Sockets = {}

  def self.build_socket_listener(ws)
    websocket = self.new
    websocket.listen(ws)
    websocket
  end

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def notify(event)
    socket = @@Sockets[self._id]
    socket.send(event.to_json)
  end
end
