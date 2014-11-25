module Slide
  module Models
    Sockets = {}
    class Buckets
      include Mongoid::Document
      field :payload, type: String
      field :key, type: String
      field :ids, type: Array, default: []

      def populate(payload)
        Bucket.find(self.id).update(payload: payload)
        socket = Sockets[@id]
        if socket
          socket.send(payload)
        end
      end

      def listen(ws)
        Sockets[self._id] = ws
      end

      def self.with_ids(key, ids)
        self.where(key: key, ids: ids)
      end
    end
  end
end

