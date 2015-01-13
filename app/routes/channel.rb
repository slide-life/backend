require 'rqrcode_png'
require 'bson'
require 'json'

require_relative '../models/channel'
require_relative '../models/user'

module NotificationJob
  @queue = :default

  def self.perform(params)
    notification = Houston::Notification.new(device: params[:device])
    notification.alert = 'Hello, World!'
    notification.custom_data = { channel: params[:channel] }
    APN.push(notification)
  end
end

module ChannelRoutes
  def self.registered(app)
    ['/channels/:id', '/channels/:id/qr', '/channels/:id/listen', '/channels/:id/request_content'].each do |pattern|
      app.before pattern do
        @oid = BSON::ObjectId.from_string(params[:id])
      end
    end

    app.post '/channels' do
      blocks, key = @request_payload['blocks'], @request_payload['key']
      number = @request_payload['number']

      user = User.find_by(number: number)
      halt_with_error 404, 'User not found.' unless user

      channel = Channel.new(key: key, blocks: blocks, number: number)

      begin
        channel.validate_blocks
      rescue InvalidBlockError => error
        halt_with_error 422, error.message
      else
        channel.save!
      end

      halt_with_error 422, 'User does not have a device registered.' if user.devices.empty?

      # TODO: request_content must deliver key in channel as well
      user.devices.each do |device| #keep for loop structure because in highly concurrent situation better this way
        # TODO: Resque.enqueue NotificationJob, device: device, channel: channel
      	NotificationJob.perform(device: device, channel: channel)
      end
      response.headers['Access-Control-Allow-Origin'] = '*'

      channel.serialize
    end

    app.get '/channels/:id' do
      channel = Channel.find(@oid)
      halt_with_error 404, 'Channel not found.' unless channel
      channel.serialize
    end

    app.post '/channels/:id' do
      channel = Channel.find(@oid)
      halt_with_error 404, "Could not find channel" unless channel
      payload_status = channel.check_payload(@request_payload)
      halt_with_error 422, "Invalid payload, error: #{payload_status}" unless payload_status == :ok

      channel.stream @request_payload
      channel.serialize
    end

    app.get '/channels/:id/qr' do
      channel = Channel.find(@oid)
      halt_with_error 404, 'Channel not found.' unless channel

      content_type 'image/png'
      qr = RQRCode::QRCode.new(params[:id])
      png = qr.to_img.resize(300, 300)
      png.to_blob
    end

    app.get '/channels/:id/listen' do
      channel = Channel.find(@oid)
      halt_with_error 404, 'Channel not found.' unless channel

      halt_with_error 422, 'No websocket.' unless request.websocket?
      request.websocket do |ws|
        ws.onopen do
          channel.listen(ws)
        end
      end
    end
  end
end

