require 'bson'

require_relative '../models/actor.rb'

module ActorRoutes
  def self.registered(app)
    ['/actors/:id', '/actors/:id/listen'].each do |pattern|
      app.before pattern do
        @oid = BSON::ObjectId.from_string(params[:id])
      end
    end

    app.post '/actors' do
      actor = Actor.new(key: @request_payload['key'])
      actor.save!
      actor.to_json
    end

    app.get '/actors/:id/listen' do
      actor = Actor.find(@oid)
      halt_with_error 404, 'Actor not found.' unless actor
      halt_with_error 422, 'No websocket.' unless request.websocket?
      request.websocket do |ws|
        ws.onopen do
          endpoint = actor.listen(ws)
          ws.onclose do
            actor.unlisten endpoint
          end
        end
      end
    end
  end
end

