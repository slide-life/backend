require_relative '../models/actor.rb'

module ActorRoutes
  def self.registered(app)
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
          actor.listen(ws)
        end
      end
    end

    app.post '/actors/:id' do
      actor = Actor.find(@oid)
      halt_with_error 404, 'Actor not found.' unless actor
      actor.stream @request_payload
      actor.to_json
    end
  end
end

