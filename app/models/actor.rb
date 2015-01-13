class Actor
  include Mongoid::Document
  field :key, type: String
  field :responses, type: Array, default: []

  @@Sockets = {}
  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def notify(payload)
    socket = @@Sockets[self._id]
    socket.send(payload) if socket
  end

  def stream(payload)
    self.responses << payload
    save!
    notify(payload.to_json)
  end
end

