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

desc 'Process SQS entries'
task :proc_sqs do |t,args|
  queue_url = format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME'])

  messages = SQSClient.receive_message( queue_url: queue_url )

  messages.messages.each do |message|
    begin
      body = JSON::parse message.body 
      pp body
      Rake::Task['article:grab'].invoke body['topic_id'], body['url']

      SQSClient.delete_message(
        queue_url: queue_url,
        receipt_handle: message.receipt_handle
      )

    rescue => e
      Log.fatal('Unable to process message: %s' % e)

    end
  end
end

namespace :topic do
  desc "Summarize"
  task :summarize, :topic_id do |t,args|
    Log.debug(format('Summarizing: %s', args[:topic_id]))
    topic = Misty::Dyn.get_topic_by_id( args[:topic_id] )
    topic.summarize
    topic.save
  end

  desc "Scrape"
  task :scrape, :key, :url do |t,args|
    uri = URI( args[:url] )
    cache_key = format('url_%s', Digest::SHA1.hexdigest( args[:url] ))
    Log.debug(format('Cache: %s', cache_key))
    data = Cache.cached( cache_key ) do
      r = RestClient.get( args[:url] )
      r.body
    end
    page = Nokogiri::HTML( data )
    cwiz = page.css("//a[@class=GUyHaf]")
    cwiz.each do |wiz|
      article_url = wiz.attributes['href'].value
      Rake::Task['article:grab'].invoke( args[:key], article_url )
      Rake::Task['article:grab'].reenable
    end
  end
end

namespace :topics do
  desc "Summarize"
  task :summarize do |t,args|
    topics = Misty::Dyn::get_topics
    topics.each do |topic|
      topic.summarize
      topic.save
    end
  end

  desc "Scrape"
  task :scrape do |t,args|
    topics = Misty::Dyn::get_topics
    topics.each do |topic|
      next if topic.topic_id == 'ca0b186cee4df7782b6555e0904ff80385336cca'

			url = topic.scrape_url
      next if url == nil

    	cache_key = format('url_%s', Digest::SHA1.hexdigest( url ))
    	data = Cache.cached( cache_key ) do
      	r = RestClient.get( url )
      	r.body
    	end
    	page = Nokogiri::HTML( data )
	
    	cwiz = page.css("//a[@class=GUyHaf]")
    	cwiz.each do |wiz|
      	article_url = wiz.attributes['href'].value
        article_key = Digest::SHA1.hexdigest( article_url )
        Log.debug(format('Scrapping article: %s', article_key))
      	Rake::Task['article:grab'].invoke( topic.topic_id, article_url )
      	Rake::Task['article:grab'].reenable
    	end
		end

  end
end

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

namespace :articles do
  desc "Analyze all body elements"
  task :analyze do |t,args|
    topics = Misty::Dyn::get_topics
    topics.each do |topic|
      articles = topic.get_articles()
      articles.each do |article|
        Log.debug(format('Processing article: %s', article.article_id))
        if article.analyze_language_body
          article.save( true )
        end
      end
    end
  end
end

namespace :article do

  desc "Map xpaths"
  task :map_xpaths do |t,args|
    mr = {}
    Misty::SOURCES_MAP.each do |hostname, xpaths|
      next if hostname == 'template'
      #pp xpaths
      xpaths.each do |k,v|
        mr[k] ||= {}
        mr[k][v] ||= 0
        mr[k][v] += 1
      end
    end
    pp mr
  end

  desc "Grab an article"
  task :grab, :key, :url do |t,args|
    Log.debug('TopicKey: %s' % args[:key]) 
    Log.debug('URL: %s' % args[:url]) 

    article = Misty::Article.new() 
    if article.process_page( args[:url], args[:key] )
      article.analyze_language()
      article.save( true )
    end
  end
end
