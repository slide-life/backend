require 'rubygems'
require 'bundler'

Bundler.require

require_relative 'config/config'
require_relative 'app/app'

run Sinatra::App
