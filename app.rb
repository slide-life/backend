require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'mongo'
require 'sinatra/cross_origin'

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
CLIENT = Mongo::MongoClient.new('ds047800.mongolab.com', 47800)
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
  def self.get(id)
    self.collection.find({ "_id" => BSON::ObjectId(id) }).to_a.map {|x|
      self.from_hash x
    }
  end
  def create!
    self.collection.insert(to_hash)
  end
  def update!
    x = to_hash
    self.collection.update({ "_id" => x["_id"] }, x)
  end
end

Buckets = DB.create_collection('buckets')
Sockets = {}
class Bucket < Model
  def self.collection
    Buckets
  end
  def initialize(key)
    @key = key
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

# Declare routes
post '/buckets' do
  content_type :json
  # TODO: use user-specific encryption key
  bucket = Bucket.new(1234)
  bucket.create!
  bucket.to_json
end
put '/buckets/:id' do
  content_type :json
  bucket = Bucket.get(params[:id])[0]
  bucket.populate request.body.read
  bucket.update!
  bucket.to_json
end
get '/buckets/:id' do
  Bucket.get(params[:id])[0].to_json
end
get '/buckets/:id/listen' do
  if request.websocket?
    request.websocket do |ws|
      ws.onopen do
	Bucket.get(params[:id])[0].listen(ws)
      end
      # TODO: remove sockets on close
    end
  else
    { :error => "No websocket." }.to_json
  end
end

