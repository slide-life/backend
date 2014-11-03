require 'sinatra'
require 'json'
require 'mongo'

# Connect to the database
CLIENT = Mongo::MongoClient.new('ds047800.mongolab.com', 47800)
DB = CLIENT['slide']
DB.authenticate('admin', 'slideinslideoutslideup')
BUCKETS = DB.create_collection('buckets')

# Declare models
class Model
  def to_hash
    Hash[instance_variables.map {|key|
      [key[1..-1], instance_variable_get(key)]
    }]
  end
  def to_json
    to_hash.to_json
  end
  def self.from_hash(hash)
    bucket = self.allocate
    hash.each { |name, value|
      bucket.instance_variable_set("@#{name}", value)
    }
    bucket
  end
  def self.get(id)
    BUCKETS.find().to_a.map {|x|
      self.from_hash x
    }
  end
  def create!
    BUCKETS.insert(to_hash)
  end
  def update!
    x = to_hash
    BUCKETS.update({ "_id" => x["_id"] }, x)
  end
end

class Bucket < Model
  def initialize(key)
    @key = key
  end
  def populate(payload)
    @payload = payload
  end
end

# Declare routes
post '/buckets' do
  content_type :json
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
  Bucket.get(params[:id]).to_json
end

