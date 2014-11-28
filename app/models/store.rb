class Store
  @@Sockets = {}

  def listen(ws)
    @@Sockets[self._id] = ws
  end

  def notify(payload)
    socket = @@Sockets[self._id]
    puts "Sending: #{payload.inspect} \n on socket #{socket.inspect}"
    socket.send(payload) if socket
  end
end
