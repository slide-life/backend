require 'sinatra/cross_origin'

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
