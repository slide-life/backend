require 'mongoid'

class Endpoint
  include Mongoid::Document
  field :url, type: String
  enum :method, [:ws, :post, :put]
  belongs_to :actor

  @@Sockets = {}

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def stream(payload)
    case :method
      when :ws
        socket = @@Sockets[self._id]
        socket.send(payload) if socket
      else
        #do nothing
    end
  end
end
