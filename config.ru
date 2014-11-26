require 'rubygems'
require 'bundler'
require 'logger'
Logger.class_eval { alias :write :'<<' }
logger = ::Logger.new(::File.new('log/app.log','a+'))

Bundler.require

require_relative 'config/config'
require_relative 'app/app'

configure do
    use Rack::CommonLogger, logger
end

run Sinatra::App
