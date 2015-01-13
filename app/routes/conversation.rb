require_relative '../models/conversation.rb'

module ConversationRoutes
  module NotificationJob
    @queue = :default

    def self.perform(params)
      notification = Houston::Notification.new(device: params[:device])
      notification.alert = params[:title]
      notification.custom_data = {
        conversation: params[:conversation],
        blocks: params[:blocks]
      }
      APN.push(notification)
    end
  end

  def self.registered(app)
    app.post '/conversations' do
      key, upstream, downstream = @request_payload['key'], @request_payload['upstream'], @request_payload['downstream']
      conversation = Conversation.new(key: key, upstream: upstream, downstream: downstream)
      conversation.save!
      conversation.to_json
    end

    app.put '/conversations/:id' do
      conversation = Conversation.find(params[:id])
      conversation.upstream! @request_payload

      # NB: assumes downstream is User
      user = User.find_by(number: conversation.downstream)
      user.patch! @request_payload['patch']

      conversation.to_json
    end

    app.post '/conversations/:id/request_content' do
      conversation = Conversation.find(params[:id])
      blocks = @request_payload['blocks']
      halt_with_error 404, 'Conversation not found.' unless conversation

      # NB: assuming downstream is a user
      user = User.find_by(number: conversation.downstream)
      halt_with_error 404, 'User not found.' unless user

      halt_with_error 422, 'User does not have a device registered.' if user.devices.empty?

      user.devices.each do |device|
        NotificationJob.perform(
          device: device,
          conversation: conversation,
          blocks: blocks,
          title: "New data request")
      end

      conversation.to_json
    end
  end
end

