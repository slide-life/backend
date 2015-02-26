require 'rubygems'
require 'bundler'

Bundler.require

require_relative 'env' if File.exists?('env.rb')
require_relative 'config/config'
require_relative 'app/app'

Dir["#{File.dirname(__FILE__)}/app/middlewares/**/*.rb"].each do |file|
  puts "Loading #{file}..."
  require file
end

use Rack::Camelize
run Sinatra::App
