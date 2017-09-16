#!/usr/bin/env ruby
require 'pp'
require 'json'
require 'koala'
require 'logger'
require 'aws-sdk'
require 'sinatra'
require 'colorize'

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', 'libs'))
#exit

require '../libs/cache.rb'
require format('%s/misty.rb', LIB_DIR)

set :bind, '0.0.0.0'
set :port, ENV['PORT']
enable :sessions
enable :logging

use Rack::Session::Cookie, :expire_after => 2592000,
  secret: '/GzPoqpDMKgsBEj9wEdOCIcctATI4zu4PB/iwj3ghOYw2NrNaRpoWoGBa1lRtd93BFtWRDVjvjHrthk4NicZfXZmJncPYsfTSFR8rI9ZYfmBtiedX6uc4E44clonFUSJ'

begin
  Log = Logger.new(STDERR)
  Tags = Misty::Tags.new()
  Cache = DevOps::Cache.new()

rescue => e
  Log.fatal(format('Failed to create logger: %s', e))
  exit

end

begin
  if ENV['USE_AWS_CREDS'] == true
    creds = Aws::SharedCredentials.new()
    S3Client = Aws::S3::Client.new(credentials: creds)
    SQSClient = Aws::SQS::Client.new(credentials: creds)
    DynamoClient = Aws::DynamoDB::Client.new(credentials: creds)

  else
    S3Client = Aws::S3::Client.new()
    SQSClient = Aws::SQS::Client.new()
    DynamoClient = Aws::DynamoDB::Client.new()

  end

rescue => e
  Log.fatal('Failed to create dynamodb client: %s' % e)
  exit

end

require './routes.rb'
