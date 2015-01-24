require 'bson'

require_relative '../models/actor.rb'

module ActorRoutes
  def self.registered(app)
    app.post '/actors' do
      halt_with_error 400, 'Needs a key.' unless @request_payload['key']
      actor = Actor.new(public_key: @request_payload['public_key'])
      actor.save!
      actor.to_json
    end

    app.namespace '/actors/:id' do
      before do
        @actor = Actor.find(params[:id])
        halt_with_error 404, 'Actor not found.' if @actor.nil?
      end

      get '/listen' do
        halt_with_error 422, 'No websocket.' unless request.websocket?
        request.websocket do |ws|
          ws.onopen do
            endpoint = @actor.listen(ws)
            ws.onclose do
              @actor.unlisten endpoint
            end
          end
        end
      end
    end
  end
end

