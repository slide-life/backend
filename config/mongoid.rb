require 'mongoid'
require 'moped'

# Options
Mongoid.load!("#{File.dirname(__FILE__)}/mongoid.yml", :development)

# Connect to the database
session = Moped::Session.new(['ds047800.mongolab.com:47800'])
session.with(database: 'slide').login('admin', 'slideinslideoutslideup')
Moped.logger = Logger.new($stdout)
Moped.logger.level = Logger::DEBUG
