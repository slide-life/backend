require './app/models/channel.rb'
require './app/models/bucket.rb'

module ChannelRoutes
  include Channel
  include Bucket
  def self.registered(app)
      app.post '/channels' do
	  channel = Channel.create!(key: @request_payload['key'], blocks: @request_payload['blocks'])
	  channel.to_json
      end

      app.get '/channels/:id' do
	  channel = Channel.find(params[:id])
	  halt_with_error 404, 'Channel not found.' unless channel
	  channel.to_json
      end

      app.post '/channels/:id' do
	  channel = Channel.find(params[:id])
	  if channel.open
	      #check payload conforms to schema set out in slide.js: fields, cipherkey
	      bucket = Bucket.find(@request_payload['bucket_id']) #TODO: any related modification
	      if bucket
		  payload_status = bucket.check_payload(@request_payload)
		  if payload_status == :ok
		      channel.stream @request_payload
		      channel.to_json
		  else
		      halt_with_error 422, "Invalid payload, error: #{payload_status}."
		  end
	      else
		  halt_with_error 422, 'Bucket not found.'
	      end
	  else
	      halt_with_error 422, 'Channel is not open.'
	  end
      end

      app.put '/channels/:id' do
	  channel = Channel.find(params[:id])
	  halt_with_error 404, 'Channel not found.' unless channel

	  channel.update(open: @request_payload['open'])
	  channel.to_json
      end

      app.get '/channels/:id/qr' do
	  channel = Channel.find(params[:id])
	  halt_with_error 404, 'Channel not found.' unless channel

	  content_type 'image/png'
	  qr = RQRCode::QRCode.new(params[:id])
	  png = qr.to_img.resize(300, 300)
	  png.to_blob
      end
  end
end


