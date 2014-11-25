require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'logger'
require 'houston'
require 'rqrcode_png'
require 'resque'

require_relative 'models/bucket.rb'
require_relative 'routes/bucket.rb'
require_relative 'models/store.rb'
require_relative 'models/channel.rb'
require_relative 'routes/channel.rb'
require_relative 'models/block.rb'

# Initializers
require_relative 'initializers/json.rb'
require_relative 'initializers/cors.rb'

Resque.redis = Redis.new

module NotificationJob
  @queue = :default

  def self.perform(params)
    notification = Houston::Notification.new(device: params[:device])
    notification.alert = 'Hello, World!'
    notification.custom_data = { bucket: params[:bucket] }
    APN.push(notification)
  end
end

module Sinatra
  class App < Sinatra::Application
    include Store
    include Bucket
    include Channel
    include Block
    register BucketRoutes
    register ChannelRoutes

    def halt_with_error(status, message)
      halt status, { error: message }.to_json
    end

    before do
      content_type :json
      body = request.body.read
      request.body.rewind
      begin
        @request_payload = JSON.parse body unless body == nil or body.length == 0
      rescue JSON::ParserError
        halt_with_error 400, 'Malformed JSON.'
      end
    end

    # Declare routes

    get '/' do
      'We have lift-off! Review the API documentation to find the list of endpoints.'
    end

    put '/users/:id/add_device' do
      user = User.find(params[:id])
      halt_with_error 404, 'User not found.' unless user

      user.update(devices: user.devices + [@request_payload['device']])
      user.to_json
    end

    get '/blocks' do
      Block.all.to_json
    end
  end
end

