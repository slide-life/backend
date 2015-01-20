require 'bson'
require_relative '../models/conversation.rb'

module ConversationRoutes
  def self.get_entity(entity)
    if entity['type'] == 'user'
      User.find_by(entity['number'])
    else
      Actor.find(BSON::ObjectId.from_string(entity['id']))
    end
  end

  def self.registered(app)
    app.post '/conversations' do
      payload = @request_payload
      upstream, downstream = ConversationRoutes.get_entity(payload['upstream']), ConversationRoutes.get_entity(payload['downstream'])
      conversation = Conversation.new(key: payload['key'],
        name: payload['name'],
        description: payload['description'],
        upstream: upstream,
        downstream: downstream)
      conversation.save!

      conversation.serialize
    end

    app.put '/conversations/:id' do
      conversation = Conversation.find(params[:id])
      conversation.upstream! @request_payload

      downstream = conversation.downstream
      if downstream.is_a? User
        conversation.downstream.patch! @request_payload['patch']
      end

      conversation.serialize
    end

    app.post '/conversations/:id/request_content' do
      conversation = Conversation.find(params[:id])
      blocks = @request_payload['blocks']
      halt_with_error 404, 'Conversation not found.' unless conversation

      downstream = conversation.downstream
      halt_with_error 404, 'Downstream not found.' unless downstream
      halt_with_error 422, 'Downstream does not have an endpoint registered.' if downstream.endpoints.empty?

      conversation.request_content! downstream, blocks

      conversation.serialize
    end

    app.post '/conversations/:id/deposit_content' do
      conversation = Conversation.find(params[:id])
      fields = @request_payload['fields']
      halt_with_error 404, 'Conversation not found.' unless conversation

      downstream = conversation.downstream
      halt_with_error 404, 'Downstream not found.' unless downstream
      halt_with_error 422, 'Downstream does not have an endpoint registered.' if downstream.endpoints.empty?

      if downstream.is_a? User
        conversation.deposit_content! downstream, fields
      else
        # TODO: deposits to actors
        actor.deposit_content! downstream, fields
      end

      conversation.serialize
    end
  end
end

