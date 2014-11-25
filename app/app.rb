require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'logger'
require 'houston'
require 'rqrcode_png'

require_relative 'routes/bucket'
require_relative 'routes/channel'
require_relative 'routes/user'
require_relative 'routes/block'

# Initializers
require_relative 'initializers/json'
require_relative 'initializers/cors'
require_relative 'initializers/resque'

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
    register BucketRoutes
    register ChannelRoutes
    register UserRoutes
    register BlockRoutes

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

    get '/' do
      { message: 'We have lift-off! Review the API documentation to find the list of endpoints.' }.to_json
    end
  end
end

