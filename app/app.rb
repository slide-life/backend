require 'sinatra'
require 'sinatra/namespace'
require 'sinatra-websocket'
require 'json'
require 'logger'

ROUTES = [
  :actor,
  :user,
  :relationship
]

# Initializers
require_relative 'initializers/json'
require_relative 'initializers/cors'
require_relative 'initializers/resque'

module Sinatra
  class App < Sinatra::Application
    ROUTES.each do |route|
      require_relative "routes/#{route.to_s}"
      register(const_get("#{route.to_s.camelize}Routes"))
    end

    def halt_with_error(status, message)
      puts "Error #{status}: #{message}"
      caller.each { |line| puts line }
      halt status, { error: message }.to_json
    end

    not_found do
      halt_with_error 404, 'Not found'
    end

    before '*' do
      content_type :json
      body = request.body.read
      request.body.rewind
      begin
        @request_payload = ::JSON.parse body unless body == nil or body.length == 0
        @request_payload ||= {}
      rescue ::JSON::ParserError
        halt_with_error 400, 'Malformed JSON.'
      end
    end

    get '/' do
      { message: 'We have lift-off! Review the API documentation to find the list of endpoints.' }.to_json
    end

    get '/static/auth.html' do
      File.read("#{File.dirname(__FILE__)}/static/auth.html")
    end
  end
end
