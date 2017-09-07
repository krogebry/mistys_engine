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
  desc "Run language analysis"
  task :lang, :topic_id, :force do |t,args|
    force = args[:force] == nil ? true : false
    Log.debug(format('Running language analysis: %s', args[:topic_id]))
    topic = Misty::Dyn.get_topic_by_id( args[:topic_id] )
    topic.get_articles.each do |article|
      article.analyze_language( force )
    end
  end

  desc "Run bias engine"
  task :be, :topic_id, :force do |t,args|
    force = args[:force] == nil ? true : false
    Log.debug(format('Running language analysis: %s', args[:topic_id]))
    topic = Misty::Dyn.get_topic_by_id( args[:topic_id] )
    topic.get_articles.each do |article|
      sum = article.get_summary_analysis( false )
      be = Misty::BiasEngine.new
      be.compile()
      be.converge( sum['syntax']['tokens'], sum['entities'] )
    end
  end

  desc "Analyize entities"
  task :anal_entities, :topic_id do |t,args|
    quote_map = {}
    salience_map = {}

    Log.debug(format('Analyizing entities for topic: %s', args[:topic_id]))
    topic = Misty::Dyn.get_topic_by_id( args[:topic_id] )

    topic.get_articles.each do |article|
      next if !article.has_body?

      sum = article.get_summary_analysis( false )

      #body = article.get_entire_body
      ## Find quotes
      #body.scan( /\s"(.*?)"\s/ ).each do |m|
        #digest = Misty::Dyn::digest( m[0] )
        #quote_map[digest] ||= { :content => m[0], :cnt => 0.0 }
        #quote_map[digest][:cnt] += 1
      #end

      be = Misty::BiasEngine.new
      be.compile()
      found = be.converge( sum['syntax']['tokens'], sum['entities'] )

      if sum == nil
        Log.debug(format('Article is missing summary: %s', article.article_id))
        exit
        #article.analyze_language( false )
        #sum = article.get_summary_analysis
      end
      sorted_by_salience = sum['entities'].map{|e| e.merge({ 'salience' => e['salience'].to_f })}.sort{|a,b| b['salience'] <=> a['salience'] }

      sorted_by_salience[0..5].each do |s|
        salience_map[s['name']] ||= { :cnt => 0.0, :salience => 0.0, :num_mentions => 0.0, :mentions => [] }
        salience_map[s['name']][:cnt] += 1
        salience_map[s['name']][:salience] += s['salience']
        salience_map[s['name']][:mentions] << s['mentions']
        salience_map[s['name']][:mentions].flatten!
        #salience_map[s['name']][:num_mentions] += s['mentions'].size
      end
    end

    #salience_map.each do |name, info|
    subject_importance_map = {}
    salience_map.sort_by{|k,v| v[:salience] }.reverse[0..10].to_h.each do |name, info|
      #pp info
      mention_map = {}
      #Log.debug(format('Subject: %s %.2f', name, info[:salience]))
      info[:mentions].each do |mention|
        next if mention['type'] != 'COMMON'
        text = mention['text']['content'].downcase
        mention_map[text] ||= { :cnt => 0.0 }
        mention_map[text][:cnt] += 1
      end
      subject_importance_map[name] = {
        :salience => info[:salience],
        :mention_map => mention_map.select{|k,v| v[:cnt] >= 1.0 }
      }
      #exit
    end

    #pp subject_importance_map

    #Misty::Dyn::save_subject_importance_map({
      #'map' => subject_importance_map,
      #'topic_id' => topic.topic_id
    #})
  end

  desc "Scrape"
  task :scrape, :key, :url do |t,args|
    if args[:url] == nil
      topic = Misty::Dyn::get_topic_by_id( args[:key] )
      url = topic.scrape_url
    else
      url = args[:url]
    end

    uri = URI( url )

    cache_key = format('url_%s', Digest::SHA1.hexdigest( url ))
    Log.debug(format('Cache: %s', cache_key))
    data = Cache.cached( cache_key ) do
      r = RestClient.get( url )
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
  desc "Summarize language"
  task :lang, :topic_id, :force do |t,args|
    force = args[:force] == nil ? true : false
    topics = Misty::Dyn::get_topics( false )
    topics.each do |topic|
      Log.debug(format('Running language analysis on topic: %s', topic.topic_id))
      topic.get_articles.each do |article|
        article.analyze_language( force )
      end
    end
  end

  desc "Run bias engine"
  task :be, :topic_id, :force do |t,args|
    force = args[:force] == nil ? true : false
    Log.debug(format('Running bias engine on topic: %s', args[:topic_id]))
    Misty::Dyn::get_topics( false ).each do |topic|
      topic = Misty::Dyn.get_topic_by_id( topic.topic_id )
      topic.get_articles.each do |article|
        sum = article.get_summary_analysis( false )
        next if !sum.has_key?( 'syntax' ) || sum['syntax'].class == Array || !sum.has_key?( 'entities' )
        be = Misty::BiasEngine.new
        be.compile()
        be.converge( sum['syntax']['tokens'], sum['entities'] )
      end
    end
  end

  desc "Scrape"
  task :scrape, :long do |t,args|
    long_timer = true if args[:long] != nil

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
      	Rake::Task['article:grab'].invoke( topic.topic_id, article_url, long_timer )
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
  desc 'Analyze'
  task :analyze, :article_key do |t,args|
    article = Misty::Dyn::get_article_by_id( args[:article_key] )
    article.analyze_language( false )
  end

  desc 'Grab by id'
  task :grab_by_id, :article_key do |t,args|
    article = Misty::Dyn::get_article_by_id( args[:article_key] )
    #article.analyze_language( false )
    #article = Misty::Article::get_by_url( args[:url] )
    if article.process_page( article.url, article.article_id )
      article.analyze_language( true )
      article.save( true )
      #Misty::nap( 'Article save', args[:long] )
    end
  end

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
  task :grab, :key, :url, :long do |t,args|
    # Log.debug('TopicKey: %s' % args[:key]) 
    # Log.debug('URL: %s' % args[:url]) 
    # Log.debug('Long: %s' % args[:long]) 
    article = Misty::Article::get_by_url( args[:url] )
    if article.process_page( args[:url], args[:key] )
      article.analyze_language( false )
      article.save( true )
      Misty::nap( 'Article save', args[:long] )
    end
  end
end
