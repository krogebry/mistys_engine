#!/usr/bin/env ruby
require 'pp'
require 'json'
#require 'dalli'
require 'koala'
require 'logger'
require 'aws-sdk'
require 'sinatra'
require 'colorize'
#require 'rack/session/dalli' 
require 'redis-rack'
require 'redis-store'
#require 'sinatra/reloader'
require "rack/session/redis"

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), '..', 'libs'))

require '../libs/cache.rb'
require format('%s/misty.rb', LIB_DIR)

set :bind, '0.0.0.0'
set :port, ENV['PORT']
enable :logging

begin
  Log = Logger.new(STDERR)
  Tags = Misty::Tags.new()
  Cache = DevOps::Cache.new()

  use Rack::Session::Redis, 
    :key => 'rack.session',
    :path => '/',
    :secret => '/GzPoqpDMKgsBEj9wEdOCIcctATI4zu4PB/iwj3ghOYw2NrNaRpoWoGBa1lRtd93BFtWRDVjvjHrthk4NicZfXZmJncPYsfTSFR8rI9ZYfmBtiedX6uc4E44clonFUSJ',
    :namespace => 'mistyengine',
    :redis_server => format('redis://%s:6379/0', ENV['CACHE_HOSTNAME']),
    :expire_after => 2592000

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
