require 'bson'
require_relative '../models/conversation.rb'

module ConversationRoutes
  def self.get_entity(entity)
    if entity['type'] == 'user'
      User.find_by(number: entity['number'])
    elsif entity['type'] == 'actor'
      Actor.find(BSON::ObjectId.from_string(entity['id']))
    else
      VendorForm.find(BSON::ObjectId.from_string(entity['id']))
    end
  end

  def self.registered(app)
    app.post '/conversations' do
      upstream, downstream =
        ConversationRoutes.get_entity(@request_payload['upstream']),
        ConversationRoutes.get_entity(@request_payload['downstream'])
      conversation = Conversation.new(key: payload['key'],
                                      name: @request_payload['name'],
                                      description: @request_payload['description'],
                                      upstream: upstream,
                                      downstream: downstream)
      conversation.save!

      conversation.serialize
    end

    app.namespace '/conversations/:id' do
      before do
        @conversation = Conversation.find(params[:id])
        halt_with_error 404, 'Conversation not found.' if @conversation.nil?

        @downstream = @conversation.downstream
        halt_with_error 404, 'Downstream not found.' if @downstream.nil?
      end

      put do
        @conversation.upstream! @request_payload
        if @downstream.is_a? Recordable
          @downstream.patch! @request_payload['patch']
        end

        @conversation.serialize
      end

      namespace '' do
        before do
          halt_with_error 422, 'Downstream does not have an endpoint registered.' if @downstream.endpoints.empty?
        end

        post '/request_content' do
          blocks = @request_payload['blocks']
          halt_with_error 422, 'No blocks.' unless blocks

          @conversation.request_content! downstream, blocks

          @conversation.serialize
        end

        post '/deposit_content' do
          fields = @request_payload['fields']
          halt_with_error 422, 'No blocks.' unless fields

          @conversation.deposit_content! downstream, fields

          @conversation.serialize
        end
      end
    end
  end
end

