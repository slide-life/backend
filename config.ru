require 'rubygems'
require 'bundler'

Bundler.require

require_relative 'config/config.rb'
require_relative 'app/app.rb'

run Sinatra::App
