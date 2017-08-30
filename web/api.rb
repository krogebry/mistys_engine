#!/usr/bin/env ruby
require 'pp'
require 'json'
require 'logger'
require 'aws-sdk'
require 'sinatra'

require '../libs/cache.rb'

set :bind, '0.0.0.0'
set :port, ENV['PORT']
enable :sessions
enable :logging

begin
  Log = Logger.new(STDERR)
  Cache = DevOps::Cache.new()

rescue => e
  Log.fatal("Failed to create logger") 
  exit

end

begin
  #creds = Aws::SharedCredentials.new()
  #DynamoClient = Aws::DynamoDB::Client.new(credentials: creds)
  DynamoClient = Aws::DynamoDB::Client.new()

rescue => e
  Log.fatal('Failed to create dynamodb client: %s' % e)
  exit

end

require './routes.rb'
