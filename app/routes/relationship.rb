require_relative '../models/actor'
require_relative '../models/relationship'
require_relative '../models/conversation'
require_relative '../models/message'

module RelationshipRoutes
  def self.registered(app)
    app.post '/relationships' do
      left  = Actor.find(@request_payload['current_user_temp']) # TODO: user sessions/API keys and current_user.id
      right = Actor.find(@request_payload['actor'])
      left_key   = @request_payload['current_user_key']
      right_key   = @request_payload['actor_key']

      halt_with_error 422, 'Requires a left actor.' unless left
      halt_with_error 422, 'Requires a right actor.' unless right
      halt_with_error 422, 'Requires keys for both parties.' unless left_key and right_key

      relationship = Relationship.new(left: left, right: right, left_key: left_key, right_key: right_key)
      relationship.save!
      relationship.serialize
    end

    app.namespace '/relationships/:relationship_id' do
      before do
        @relationship = Relationship.find(params[:relationship_id])
        halt_with_error 404, 'Relationship not found.' if @relationship.nil?
      end

      get '' do
        @relationship.serialize
      end

      get '/conversations' do
        @relationship.conversations.to_json
      end

      post '/conversations' do
        name = @request_payload['name']
        halt_with_error 422, 'Requires a name.' unless name

        conversation = Conversation.new(name: name)
        @relationship.conversations << conversation
        @relationship.save!

        conversation.to_json
      end

      namespace '/conversations/:conversation_id' do
        before do
          @conversation = Conversation.find(params[:conversation_id])
          halt_with_error 404, 'Conversation not found.' if @conversation.nil?
        end

        get '' do
          @conversation.to_json
        end

        get '/messages' do
          @conversation.messages.to_json
        end

        post '/requests' do
          # TODO: use session authentication to get left/right and authenticate
          to    = @request_payload['to']
          left  = @relationship.left_id.to_s
          right = @relationship.right_id.to_s
          halt_with_error 422, 'Invalid receiver.' unless [left, right].include? to
          target = (left == to) ? :left : :right
          target_actor = (left == to) ? @relationship.left : @relationship.right

          # TODO: validate blocks
          blocks = @request_payload['blocks']

          request = Request.new(to: target, blocks: blocks)
          @conversation.messages << request
          @conversation.save!

          target_actor.notify(request.as_event)

          request.to_json
        end

        post '/requests/:request_id' do
          request = Request.find(params[:request_id])
          request.read = true
          request.save!
          halt_with_error 404, 'Request not found.' if request.nil?

          # TODO: validate that data corresponds to request
          data = @request_payload['data']
          #request.blocks.each do |block|
          #  halt_with_error 422, "Block required: #{block}." unless data[block]
          #end

          # TODO: use session authentication to get left/right and authenticate
          target = (request.to == :left) ? :right : :left
          target_actor = (request.to == :left) ? @relationship.right : @relationship.left

          response = Response.new(to: target, data: data)
          response.request = request
          @conversation.messages << response
          @conversation.save!

          target_actor.notify(response.as_event)

          response.to_json
        end
      end
    end
  end
end
