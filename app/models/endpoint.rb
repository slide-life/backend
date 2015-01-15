require 'mongoid'

class Endpoint
  include Mongoid::Document
  include Mongoid::Enum
  field :url, type: String
  enum :method, [:ws, :post, :put]
  belongs_to :actor

  @@Sockets = {}

  def listen(ws)
    puts "Now listening!"
    @@Sockets[self._id] = ws
  end

  def stream(payload)
    case self.method
      when :ws
        socket = @@Sockets[self._id]
        puts "Sending to socket: #{socket}"
        socket.send(payload) if socket
      else
        #do nothing
    end
  end
end
