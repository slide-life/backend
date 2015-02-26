require_relative '../models/actor'
require_relative './_actor_shared'

module ActorRoutes
  def self.registered(app)
    actor_routes(app, Actor)

    app.post '/actors' do
      key = @request_payload['key']

      halt_with_error 422, 'Requires a public key.' unless key

      actor = Actor.new(key: key)
      actor.save!
      actor.to_json
    end
  end
end
