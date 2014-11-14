require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'mongo'
require 'logger'
require 'houston'
require 'sinatra/cross_origin'
require 'mongoid'

# Setup
Mongoid.load!("#{Dir.pwd}/mongoid.yml", :development)

APN = Houston::Client.development
APN.certificate = File.read("#{Dir.pwd}/pushcert.pem")

configure do
  enable :cross_origin
  set :allow_origin, :any
  set :allow_methods, [:get, :post, :options, :put]
end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
  halt 200
end

# Connect to the database
CLIENT = Mongo::MongoClient.new('ds047800.mongolab.com', 47800, :logger => Logger.new(STDOUT))
DB = CLIENT['slide']
DB.authenticate('admin', 'slideinslideoutslideup')

Sockets = {}
class Bucket
  include Mongoid::Document
  field :payload, type: String
  field :key, type: String
  field :ids, type: Array, default: []
  def populate(payload)
    Bucket.find(self.id).update(payload: payload)
    socket = Sockets[@id]
    if socket
      socket.send(payload)
    end
  end
  def listen(ws)
    Sockets[self._id] = ws
  end
  def self.with_ids(key, ids)
    self.where(key: key, ids: ids)
  end
end

class Field
  include Mongoid::Document
  field :name, type: String
  field :description, type: String
  field :typeName, type: String
  field :typeId, type: String
end

class User
  include Mongoid::Document
  field :username, type: String
  field :devices, type: Array, default: []
end

before do
  content_type :json
  request.body.rewind
  @request_payload = JSON.parse request.body.read unless request.body.length == 0
end

class InvalidFieldError < StandardError
end

# Declare routes

get '/' do
  'We have lift-off! Review the API documentation to find the list of endpoints'  
end

post '/buckets' do
  fields = @request_payload

  if fields.length == 0
    halt 400, 'You cannot create a bucket with no fields'
  end

  duplicate_fields = fields.select { |field| fields.count(field) > 1 }.uniq
  if duplicate_fields.length > 0
    halt 400, "You cannot create a bucket with duplicate fields. You have included #{duplicate_fields.join(' ,')} twice"
  end

  validated_fields = Field.where(:name.in => fields)
  unless fields.length == validated_fields.length
    invalid_fields = fields - validated_fields.map { |field| field.name }
    halt 400, "The field(s) #{invalid_fields.join(' ,')} are invalid"
  end

  # TODO: use user-specific encryption key
  # TODO: use field ids
  ids = validated_fields.map { |field| field.id }
  bucket = Bucket.with_ids(1234, ids)
  bucket.create!
  bucket.to_json
end

post '/buckets/:id' do
  bucket = Bucket.find(params[:id])
  bucket.populate @request_payload
  Bucket.find(params[:id]).to_json
end

put '/users/:id/add_device' do
  user = User.find(params[:id])
  halt 404, 'User does not exist' unless user

  user.update(devices: user.devices + [@request_payload['device']])
  user.to_json
end

put '/buckets/:id/request_content' do
  user = User.find_by(username: @request_payload['user'])
  halt 404, 'User does not exist' unless user
  halt 400, 'User does not have a device registered' if user.devices.empty?
 
  bucket = Bucket.find(params[:id]).get_fields
  # TODO: make async
  user.devices.each do |device|
    notification = Houston::Notification.new(device: device)
    notification.alert = 'Hello, World!'
    notification.custom_data = { bucket: bucket }
    APN.push(notification)
  end

  200
end

get '/buckets/:id' do
  Bucket.find(params[:id]).to_json
end

get '/buckets/:id/listen' do
  if request.websocket?
    request.websocket do |ws|
      ws.onopen do
        Bucket.find(params[:id]).listen(ws)
      end
      # TODO: remove sockets on close
    end
  else
    { :error => "No websocket." }.to_json
  end
end

