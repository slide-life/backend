require_relative '../models/conversation.rb'

module ConversationRoutes
  def self.registered(app)
    app.post '/conversations' do
      key, upstream, downstream = @request_payload['key'], @request_payload['upstream'], @request_payload['downstream']
      conversation = Conversation.new(key: key, upstream: upstream, downstream: downstream)
      conversation.save!
      conversation.to_json
    end

    app.put '/conversations/:id' do
      conversation = Conversation.find(params[:id])
      halt_with_error 404, 'Conversation not found.' unless actor
    end
  end
end

