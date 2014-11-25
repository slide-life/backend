require 'rubygems'
require 'bundler'

Bundler.require

require './app/app.rb'

run Sinatra::App

