class Store
  @@Sockets = {}

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def notify(payload)
    socket = @@Sockets[self._id]
    socket.send(payload) if socket
  end
end
