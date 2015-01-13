require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'logger'

require_relative 'routes/channel'
require_relative 'routes/user'
require_relative 'routes/block'
require_relative 'routes/actor'

# Initializers
require_relative 'initializers/json'
require_relative 'initializers/cors'
require_relative 'initializers/resque'

module Sinatra
  class App < Sinatra::Application
    register ChannelRoutes
    register UserRoutes
    register BlockRoutes
    register ActorRoutes

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
