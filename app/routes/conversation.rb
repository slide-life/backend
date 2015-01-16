require_relative '../models/conversation.rb'

module ConversationRoutes
  module NotificationJob
    @queue = :default

    def self.perform(params)
      params[:device].push(params[:title], {
        conversation: params[:conversation],
        blocks: params[:blocks]
      })
    end
  end

  def self.registered(app)
    app.post '/conversations' do
      conversation = Conversation.new(@request_payload)
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

