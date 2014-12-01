require 'houston'

require_relative '../models/bucket'
require_relative '../models/user'

module NotificationJob
  @queue = :default

  def self.perform(params)
    notification = Houston::Notification.new(device: params[:device])
    notification.alert = 'Hello, World!'
    notification.custom_data = {bucket: params[:bucket]}
    APN.push(notification)
  end
end

module BucketRoutes
  def self.registered(app)
    app.post '/buckets' do
      blocks, key = @request_payload['blocks'], @request_payload['key']
      bucket = Bucket.new(key: key, blocks: blocks)
      
      begin
        bucket.validate_blocks
      rescue InvalidBlockError => error
        halt_with_error 422, error.message
      else
        bucket.save!
        bucket.to_json
      end
    end

    app.get '/buckets/:id' do
      bucket = Bucket.find(params[:id])
      halt_with_error 404, 'Bucket not found.' unless bucket
      bucket.to_json
    end

    app.post '/buckets/:id' do
      bucket = Bucket.find(params[:id])
      payload_status = bucket.check_payload(@request_payload)
      halt_with_error 422, "Invalid payload, error: #{payload_status}" unless payload_status == :ok

      bucket.populate @request_payload
      204
    end

    app.get '/buckets/:id/listen' do
      if request.websocket?
        request.websocket do |ws|
          ws.onopen do
            Bucket.find(params[:id]).listen(ws)
          end
          # TODO: remove sockets on close
        end
      else
        halt_with_error 422, 'No websocket.'
      end
    end

    app.put '/buckets/:id/request_content' do
      user = User.find_by(username: @request_payload['user'])
      halt_with_error 404, 'User not found.' unless user
      halt_with_error 422, 'User does not have a device registered.' if user.devices.empty?

      bucket = Bucket.find(params[:id]).get_fields
      # TODO: request_content must deliver key in bucket as well
      user.devices.each do |device| #keep for loop structure because in highly concurrent situation better this way
        Resque.enqueue NotificationJob, device: device, bucket: bucket
      end

      204
    end
  end
end
