require 'sinatra'
require 'json'
require 'mongo'

client = MongoClient('ds047800.mongolab.com', 47800)
db = client['slide']
db.authenticate('admin', 'slideinslideoutslideup')

post '/buckets' do
  content_type :json
  { id: "Hello World!" }.to_json
end

