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

module Junk
    class JunkApp < Sinatra::Application
	# Connect to the database
	session = Moped::Session.new(['ds047800.mongolab.com:47800'])
	session.with(database: 'slide').login('admin', 'slideinslideoutslideup')
	Moped.logger = Logger.new($stdout)
	Moped.logger.level = Logger::DEBUG

	def halt_with_error(status, message)
	    halt status, { error: message }.to_json
	end

	Sockets = {}
	class Store
	    def push(item)

	    end
	    def listen(ws)
		Sockets[self._id] = ws
	    end
	    def notify(payload)
		socket = Sockets[@id]
		if socket
		    socket.send(payload)
		end
	    end
	end

	class Bucket < Store
	    include Mongoid::Document
	    field :key, type: String
	    field :blocks, type: Array, default: []
	    field :payload, type: String
	    def populate(payload)
		payload = payload
		save!
	    end

	    def check_payload(payload)
		if payload['fields']
		    if payload['cipherkey']
			if payload['fields'].keys.uniq.count != payload['fields'].keys.count
			    'Duplicate fields.'
			elsif ! payload['fields'].keys.to_set.equal?(self.blocks.to_set)
			    'Fields are not the same as blocks.'
			end
		    else
			'No cipherkey.'
		    end
		else
		    'No fields.'
		end
	    end
	end

	class Channel < Store
	    include Mongoid::Document
	    field :key, type: String
	    field :blocks, type: Array, default: []
	    field :buckets, type: Array, default: []
	    field :open, type: Boolean, default: false
	    def stream(payload)
		push(buckets: payload)
		notify(payload)
	    end
	end

	class Block
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

	module NotificationJob
	    @queue = :default
	    def self.perform(params)
		notification = Houston::Notification.new(device: params[:device])
		notification.alert = 'Hello, World!'
		notification.custom_data = { bucket: params[:bucket] }
		APN.push(notification)
	    end
	end

	before do
	    content_type :json
	    request.body.rewind
	    begin
		@request_payload = JSON.parse request.body.read unless request.body.length == 0
	    rescue JSON::ParserError
		halt_with_error 400, 'Malformed JSON.'
	    end
	end

	# Declare routes

	get '/' do
	    'We have lift-off! Review the API documentation to find the list of endpoints.'
	end

	post '/buckets' do
	    blocks, key = @request_payload['blocks'], @request_payload['key']

	    if blocks.length == 0
		halt_with_error 422, 'You cannot create a bucket with no blocks.'
	    end

	    duplicate_blocks = blocks.select { |block| blocks.count(block) > 1 }.uniq
	    if duplicate_blocks.length > 0
		halt_with_error 422, "You cannot create a bucket with duplicate blocks. You have included #{duplicate_blocks.join(' ,')} twice."
	    end

	    validated_blocks = Block.where(:name.in => blocks)
	    unless blocks.length == validated_blocks.length
		invalid_blocks = blocks - validated_blocks.map { |block| block.name }
		halt_with_error 422, "The block(s) #{invalid_blocks.join(', ')} are invalid."
	    end

	    bucket = Bucket.create!(key: key, blocks: validated_blocks.map { |block| block.id })
	    bucket.inspect
	    bucket.to_json
	end

	post '/buckets/:id' do
	    bucket = Bucket.find(params[:id])
	    bucket.populate @request_payload # TODO: validate that the payload has blocks and cipherkey
	    204
	end

	put '/users/:id/add_device' do
	    user = User.find(params[:id])
	    halt_with_error 404, 'User not found.' unless user

	    user.update(devices: user.devices + [@request_payload['device']])
	    user.to_json
	end

	put '/buckets/:id/request_content' do
	    user = User.find_by(username: @request_payload['user'])
	    halt_with_error 404, 'User not found.' unless user
	    halt_with_error 422, 'User does not have a device registered.' if user.devices.empty?

	    bucket = Bucket.find(params[:id]).get_fields
	    # TODO: request_content must deliver key in bucket as well
	    user.devices.each do |device| #keep for loop structure because in highly concurrent situation better this way
		Resque.enqueue NotificationJob, device: device, bucket: bucket
	    end

	    200
	end

	get '/buckets/:id' do
	    bucket = Bucket.find(params[:id])
	    halt_with_error 404, 'Bucket not found.' unless bucket
	    bucket.to_json
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
		halt_with_error 422, 'No websocket.'
	    end
	end

	post '/channels' do
	    channel = Channel.create!(key: @request_payload['key'], blocks: @request_payload['blocks'])
	    channel.to_json
	end

	get '/channels/:id' do
	    channel = Channel.find(params[:id])
	    halt_with_error 404, 'Channel not found.' unless channel
	    channel.to_json
	end

	post '/channels/:id' do
	    channel = Channel.find(params[:id])
	    if channel.open
		#check payload conforms to schema set out in slide.js: fields, cipherkey
		bucket = Bucket.find(@request_payload['bucket_id']) #TODO: any related modification
		if bucket
		    payload_status = bucket.check_payload(@request_payload)
		    if payload_status == :ok
			channel.stream @request_payload
			channel.to_json
		    else
			halt_with_error 422, "Invalid payload, error: #{payload_status}."
		    end
		else
		    halt_with_error 422, 'Bucket not found.'
		end
	    else
		halt_with_error 422, 'Channel is not open.'
	    end
	end

	put '/channels/:id' do
	    channel = Channel.find(params[:id])
	    halt_with_error 404, 'Channel not found.' unless channel

	    channel.update(open: @request_payload['open'])
	    channel.to_json
	end

	get '/channels/:id/qr' do
	    channel = Channel.find(params[:id])
	    halt_with_error 404, 'Channel not found.' unless channel

	    content_type 'image/png'
	    qr = RQRCode::QRCode.new(params[:id])
	    png = qr.to_img.resize(300, 300)
	    png.to_blob
	end
    end
end

