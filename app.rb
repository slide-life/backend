require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'mongo'
require 'logger'
require 'houston'
require 'sinatra/cross_origin'

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

# Declare models
class Model
  def to_hash
    Hash[instance_variables.map {|key|
      [key[1..-1], instance_variable_get(key)]
    }.reject {|x|
      x[0].start_with? "__"
    }]
  end
  def to_json
    to_hash.to_json
  end
  def collection
    self.class.collection
  end
  def self.from_hash(hash)
    bucket = self.allocate
    hash.each { |name, value|
      bucket.instance_variable_set("@#{name}", value)
    }
    bucket
  end
  def create!
    self.collection.insert(to_hash)
  end
  def update!
    x = to_hash
    self.collection.update({ "_id" => x["_id"] }, x)
  end
  def self.find_by_id(id)
    self.find_one({ "_id" => BSON::ObjectId(id) })
  end
  def self.find_one(*args)
    self.from_hash self.collection.find_one(*args)
  end
  def self.find(*args)
    self.collection.find(*args).to_a.map {|x|
      self.from_hash x
    }
  end
end

Sockets = {}
Buckets = DB.create_collection('buckets')
class Bucket < Model
  def self.collection
    Buckets
  end
  def initialize(key, fields)
    @key = key
    @fields = fields
    @__socket = nil
    @id = create!.to_s
  end
  def populate(payload)
    @payload = payload
    socket = Sockets[@id]
    if socket
      socket.send(payload)
    end
  end
  def listen(ws)
    Sockets[@id] = ws
  end
end

Fields = DB.create_collection('fields')
class Field < Model
  def self.collection
    Fields
  end
end

Users = DB.create_collection('users')
class User < Model
  def self.collection
    Users
  end
end

before do
  content_type :json
  request.body.rewind
  @request_payload = JSON.parse request.body.read
end

class InvalidFieldError < StandardError
end

# Declare routes

post '/buckets' do
  fields = @request_payload

  if fields.length == 0
    halt 400, 'You cannot create a bucket with no fields'
  end

  duplicate_fields = fields.select { |field| fields.count(field) > 1 }.uniq
  if duplicate_fields.length > 0
    halt 400, "You cannot create a bucket with duplicate fields. You have included #{duplicate_fields.join(' ,')} twice"
  end

  validated_fields = Field.find({ name: { '$in' => fields } })
  unless fields.length == validated_fields.length
    invalid_fields = fields - validated_fields.map { |field| field['name'] }
    halt 400, "The field(s) #{invalid_fields.join(' ,')} are invalid"
  end

  # TODO: use user-specific encryption key
  # TODO: use field ids
  bucket = Bucket.new(1234, validated_fields.map { |field| field['_id'] })
  bucket.create!
  bucket.to_json
end

put '/buckets/:id' do
  bucket = Bucket.find_by_id(params[:id])
  bucket.populate request.body.read
  bucket.update!
  bucket.to_json
end

put '/buckets/:id/notify' do
  user = User.find_one({ username: @request_payload['user'] })
  halt 400, 'User does not exist' unless user
  halt 400, 'User does not have a device registered' unless user['token']
 
  bucket = Bucket.find_by_id(params[:id])
  notification = Houston::Notification.new(device: user['token'])
  notification.alert = 'Hello, World!'
  notification.custom_data = { fields: bucket['fields'] }
  APN.push(notification)
end

get '/buckets/:id' do
  Bucket.find_by_id(params[:id]).to_json
end

get '/buckets/:id/listen' do
  if request.websocket?
    request.websocket do |ws|
      ws.onopen do
      	Bucket.find_by_id(params[:id]).listen(ws)
      end
      # TODO: remove sockets on close
    end
  else
    { :error => "No websocket." }.to_json
  end
end
