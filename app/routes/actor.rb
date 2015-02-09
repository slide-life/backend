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

      patch '' do
        profile = @request_payload['profile']
        halt_with_error 422, 'Patch requires a profile.' unless profile

        @actor.profile = Profile.new if @actor.profile.nil?
        @actor.profile.patch(profile)

        @actor.save!
        @actor.to_json
      end

      get '/relationships' do
        Relationship.or({ left: @actor}, {right: @actor }).to_json
      end

      get '/listen' do
        halt_with_error 422, 'No websocket.' unless request.websocket?

        request.websocket do |ws|
          ws.onopen do
            listener = @actor.listen!(ws)
            ws.onclose do
              @actor.unlisten!(listener)
            end
          end
        end
      end

      post '/listeners' do
        type = @request_payload['type']

        case (type)
          when 'webhook'
            listener = Webhook.new(url: @request_payload['url'])
            listener.save!

            @actor.listeners << listener
            @actor.save!
        end

        @actor.to_json
      end
    end
  end
end
