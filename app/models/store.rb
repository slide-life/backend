class Store
  @@Sockets = {}

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def notify(payload)
    socket = @@Sockets[@id]
    socket.send(payload) if socket
  end
end
