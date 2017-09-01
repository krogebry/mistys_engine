#!/usr/bin/env ruby
require 'pp'
require 'json'
require 'logger'
require 'aws-sdk'
require 'sinatra'
require 'colorize'

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', 'libs'))
#exit

require '../libs/cache.rb'
#require '../libs/misty.rb'
require format('%s/misty.rb', LIB_DIR)

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
  if ENV['USE_AWS_CREDS'] == true
    creds = Aws::SharedCredentials.new()
    SQSClient = Aws::SQS::Client.new(credentials: creds)
    DynamoClient = Aws::DynamoDB::Client.new(credentials: creds)
  else
    SQSClient = Aws::SQS::Client.new()
    DynamoClient = Aws::DynamoDB::Client.new()
  end

rescue => e
  Log.fatal('Failed to create dynamodb client: %s' % e)
  exit

end

require './routes.rb'
