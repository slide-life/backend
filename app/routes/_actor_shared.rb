require_relative '../models/actor'

def actor_routes(app, model_klass)
  model_lower_name = model_klass.name.underscore.pluralize

  app.namespace "/#{model_lower_name}/:id" do
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
      Relationship.of_actor(@actor).to_json
    end

    get '/relationships/with/:other_id' do
      other_actor = Actor.find(params[:other_id])
      halt_with_error 400, 'Other actor couldn\'t be found.' unless other_actor

      relationship = Relationship.between(@actor, other_actor)

      if relationship.count > 0
        { exists: true, relationship: relationship.first }.to_json
      else
        { exists: false }.to_json
      end
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
