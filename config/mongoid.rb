require 'mongoid'
require 'moped'

# Connect to the database
Mongoid.load!("#{File.dirname(__FILE__)}/mongoid.yml", ENV['RACK_ENV'])

# Logging
Moped.logger = Logger.new($stdout)
Moped.logger.level = Logger::DEBUG
