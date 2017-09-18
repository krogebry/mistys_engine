require 'pp'
require 'json'
require 'logger'
require 'aws-sdk'
require 'nokogiri'
require 'colorize'
require 'fileutils'
require 'rest-client'
require 'digest/sha1'

require './libs/cache.rb'

LIB_DIR = File.expand_path(File.join(File.dirname(__FILE__), 'libs'))

require format('%s/misty.rb' % LIB_DIR)

Log = Logger.new(STDOUT)
Cache = DevOps::Cache.new

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

require './tasks/sqs.rb'
require './tasks/topic.rb'
require './tasks/article.rb'

namespace :sources do
  desc "Summarize all sources"
  task :summarize do |t,args|
    source_map = {}

    topics = Misty::Dyn::get_topics
    topics.each do |topic|
      if !topic.has_summary?
        Log.info(format('No summary for %s', topic.topic_id).yellow)
        next
      end
      Log.info(format('Looking at summary for %s', topic.topic_id).green)

      articles = topic.get_articles( false )
      articles.each do |article|
        if article.source == 'www.cnn.com'
          Log.debug(format('Score: %.2f / %.2f', article.magnitude, article.score))
        end
        source_map[article.source] ||= { :cnt => 0.0, :mag => 0.0, :score => 0.0 }
        source_map[article.source][:cnt] += 1
        source_map[article.source][:mag] += article.magnitude
        source_map[article.source][:score] += article.score
      end
    end

    source_map.each do |source, info|
      info[:pct_mag] = info[:mag] / info[:cnt]
      info[:pct_score] = info[:score] / info[:cnt]
    end

    #pp source_map
    source_map.each do |source, info|
      next if info[:mag] == 0 && info[:score] == 0
      puts format('%s: count(%i) | mag(%.2f%%) | score(%.2f%%)', source, info[:cnt], info[:pct_mag], info[:pct_score])
    end
  end
end

