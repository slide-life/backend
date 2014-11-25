module Store
  Sockets = {}
  class Store
    def listen(ws)
      Sockets[self._id] = ws
    end

    def notify(payload)
      socket = Sockets[@id]
      if socket
        socket.send(payload)
      end
    end
  end
end

