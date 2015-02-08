require_relative '../models/actor'

module ActorRoutes
  def self.registered(app)
    app.post '/actors' do
      key = @request_payload['key']

      halt_with_error 422, 'Requires a public key.' unless key

      actor = Actor.new(key: key)
      actor.save!
      actor.to_json
    end

    app.namespace '/actors/:id' do
      before do
        @actor = Actor.find(params[:id])
        halt_with_error 404, 'Actor not found.' if @actor.nil?
      end

      get '' do
        @actor.to_json
      end

      get '/relationships' do
        Relationship.or({ left: @actor}, {right: @actor }).to_json
      end
    end
  end
end
