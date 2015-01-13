require_relative '../models/conversation.rb'

module ConversationRoutes
  def self.registered(app)
    app.post '/conversations' do
      key, upstream, downstream = @request_payload['key'], @request_payload['upstream'], @request_payload['downstream']
      conversation = Conversation.new(key: key, upstream: upstream, downstream: downstream)
      conversation.save!

      # NB: assuming downstream is a user
      user = User.find_by(number: downstream)
      halt_with_error 404, 'User not found.' unless user

      halt_with_error 422, 'User does not have a device registered.' if user.devices.empty?

      user.devices.each do |device|
        NotificationJob.perform(device: device, channel: conversation)
      end

      conversation.to_json
    end

    app.put '/conversations/:id' do
      conversation = Conversation.find(params[:id])
      halt_with_error 404, 'Conversation not found.' unless actor
    end
  end
end

