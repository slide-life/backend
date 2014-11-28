require 'rqrcode_png'
require 'bson'

require_relative '../models/channel'
require_relative '../models/bucket'

module ChannelRoutes
  def self.registered(app)
    ['/channels/:id', '/channels/:id/qr', '/channels/:id/listen'].each do |pattern|
      app.before pattern do
        @oid = BSON::ObjectId.from_string(params[:id])
      end
    end

    app.post '/channels' do
      channel = Channel.create!(key: @request_payload['key'], blocks: @request_payload['blocks'])
      channel.to_json
    end

    app.get '/channels/:id' do
      channel = Channel.find(@oid)
      halt_with_error 404, 'Channel not found.' unless channel
      channel.to_json
    end

    app.post '/channels/:id' do
      channel = Channel.find(@oid)
      if channel.open
        #check payload conforms to schema set out in slide.js: fields, cipherkey
        payload_status = channel.check_payload(@request_payload)
        if payload_status == :ok
          channel.stream @request_payload.to_json
          channel.to_json
        else
          halt_with_error 422, "Invalid payload, error: #{payload_status}."
        end
      else
        halt_with_error 422, 'Channel is not open.'
      end
    end

    app.put '/channels/:id' do
      channel = Channel.find(@oid)
      halt_with_error 404, 'Channel not found.' unless channel

      channel.update(open: @request_payload['open'])
      channel.to_json
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

      if request.websocket?
        puts 'Request is websocket.'
        request.websocket do |ws|
          ws.onopen do
            channel.listen(ws)
          end
        end
      else
        puts 'No websocket.'
        halt_with_error 422, 'No websocket.'
      end
    end
  end
end
