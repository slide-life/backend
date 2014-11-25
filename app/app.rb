require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'logger'
require 'houston'
require 'sinatra/cross_origin'
require 'mongoid'
require 'moped'
require 'rqrcode_png'
require 'resque'

require './app/models/bucket.rb'
require './app/routes/bucket.rb'
require './app/models/store.rb'
require './app/models/channel.rb'
require './app/routes/channel.rb'
require './app/models/block.rb'

# Setup
Mongoid.load!("#{Dir.pwd}/mongoid.yml", :development)

Resque.redis = Redis.new

APN = Houston::Client.development
APN.certificate = File.read("#{Dir.pwd}/pushcert.pem")

configure do
  enable :cross_origin
  set :allow_origin, :any
  set :allow_methods, [:get, :post, :options, :put]
end

options '*' do
  response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  halt 200
end

# Initializers

module BSON
  class ObjectId
    alias :to_json :to_s
  end
end

module Mongoid
  module Document
    def to_json(options={})
      attrs = super(options)
      attrs['id'] = attrs['_id']
      attrs.delete '_id'
      attrs
    end
  end
end

module Block
  class Block
    include Mongoid::Document
    field :name, type: String
    field :description, type: String
    field :typeName, type: String
    field :typeId, type: String
  end
end

module User
  class User
    include Mongoid::Document
    field :username, type: String
    field :devices, type: Array, default: []
  end
end

module NotificationJob
  @queue = :default

  def self.perform(params)
    notification = Houston::Notification.new(device: params[:device])
    notification.alert = 'Hello, World!'
    notification.custom_data = {bucket: params[:bucket]}
    APN.push(notification)
  end
end

module Sinatra
  class App < Sinatra::Application
    include Store
    include Bucket
    register BucketRoutes
    include Channel
    register ChannelRoutes
    include Block
    # Connect to the database
    session = Moped::Session.new(['ds047800.mongolab.com:47800'])
    session.with(database: 'slide').login('admin', 'slideinslideoutslideup')
    Moped.logger = Logger.new($stdout)
    Moped.logger.level = Logger::DEBUG

    def halt_with_error(status, message)
      halt status, {error: message}.to_json
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

