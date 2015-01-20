require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'logger'

ROUTES = [
  :admin,
  :user,
  :block,
  :actor,
  :conversation,
  :device,
  :endpoint,
  :relationship,
  :vendor,
  :vendor_form
]

ROUTES.each do |model_name|
  require_relative "routes/#{model_name.to_s}"
end

# Initializers
require_relative 'initializers/json'
require_relative 'initializers/cors'
require_relative 'initializers/resque'

module Sinatra
  class App < Sinatra::Application
    def self.register_model(model)
      constant_name = model.to_s.camelize
      register(const_get(constant_name + "Routes"))
    end

    ROUTES.each do |model_name|
      register_model(model_name)
    end

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
