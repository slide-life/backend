require 'houston'

require_relative '../models/bucket'
require_relative '../models/block'
require_relative '../models/user'

module NotificationJob
    @queue = :default

    def self.perform(params)
        notification = Houston::Notification.new(device: params[:device])
        notification.alert = 'Hello, World!'
        notification.custom_data = { bucket: params[:bucket] }
        APN.push(notification)
    end
end

module BucketRoutes
    def self.registered(app)
        app.put '/buckets/:id/request_content' do
            user = User.find_by(username: @request_payload['user'])
            halt_with_error 404, 'User not found.' unless user
            halt_with_error 422, 'User does not have a device registered.' if user.devices.empty?

            bucket = Bucket.find(params[:id]).get_fields
            # TODO: request_content must deliver key in bucket as well
            user.devices.each do |device| #keep for loop structure because in highly concurrent situation better this way
                Resque.enqueue NotificationJob, device: device, bucket: bucket
            end

            200
        end

        app.get '/buckets/:id' do
            bucket = Bucket.find(params[:id])
            halt_with_error 404, 'Bucket not found.' unless bucket
            bucket.to_json
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

        app.post '/buckets/:id' do
            bucket = Bucket.find(params[:id])
            bucket.populate @request_payload # TODO: validate that the payload has blocks and cipherkey
            204
        end
<<<<<<< HEAD
      else
        halt_with_error 422, 'No websocket.'
      end
    end
    
    app.post '/buckets/:id' do
      bucket = Bucket.find(params[:id])
      bucket.populate @request_payload # TODO: validate that the payload has blocks and cipherkey
      204
    end
=======
>>>>>>> 4b078d148a52696a415f45acd466e942f13f7637

        app.post '/buckets' do
            blocks, key = @request_payload['blocks'], @request_payload['key']

            if blocks.length == 0
                halt_with_error 422, 'You cannot create a bucket with no blocks.'
            end

            duplicate_blocks = blocks.select { |block| blocks.count(block) > 1 }.uniq
            if duplicate_blocks.length > 0
                halt_with_error 422, "You cannot create a bucket with duplicate blocks. You have included #{duplicate_blocks.join(' ,')} twice."
            end

            validated_blocks = Block.where(:name.in => blocks)
            unless blocks.length == validated_blocks.length
                invalid_blocks = blocks - validated_blocks.map { |block| block.name }
                halt_with_error 422, "The block(s) #{invalid_blocks.join(', ')} are invalid."
            end

            bucket = Bucket::Bucket.create!(key: key, blocks: validated_blocks.map { |block| block.id })
            bucket.to_json
        end
    end
end
