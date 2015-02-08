require 'bson'

require_relative '../models/actor'
require_relative '../models/relationship'
require_relative '../models/conversation'

module RelationshipRoutes
  def self.registered(app)
    app.post '/relationships' do
      left  = Actor.find(@request_payload['current_user_temp']) # TODO: user sessions/API keys and current_user.id
      right = Actor.find(@request_payload['user'])
      key   = @request_payload['key']

      halt_with_error 422, 'Requires a left actor.' unless left
      halt_with_error 422, 'Requires a right actor.' unless right
      halt_with_error 422, 'Requires a key.' unless key

      relationship = Relationship.new(left: left, right: right, right_key: key)
      relationship.save!
      relationship.to_json
    end

    app.post '/relationships/:id/conversations' do
      relationship = Relationship.find(params[:id])
      name = @request_payload['name']

      halt_with_error 404, 'Relationship not found.' if relationship.nil?
      halt_with_error 422, 'Requires a name.' unless name

      conversation = Conversation.new(name: name)
      relationship.conversations << conversation
      conversation.to_json
    end
  end
end
