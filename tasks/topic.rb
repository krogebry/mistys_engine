
namespace :topic do
  desc "Run language analysis"
  task :lang, :topic_id, :force do |t,args|
    force = args[:force] == nil ? false : true
    topic = Misty::Dyn.get_topic_by_id( args[:topic_id] )
    Log.debug(format('Running language analysis: %s (%s)', topic.topic_id, force))
    topic.get_articles.each do |article|
      article.analyze_language( force )
      # pp article
    end
  end

  desc "Run occurance mapping."
  task :create_om, :topic_id do |t,args|
    message = { 'topic_id' => args[:topic_id] }
    SQSClient.send_message(
      queue_url: format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_create_om', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME']),
      message_body: message.to_json
    )
  end

  desc "Run bias engine"
  task :be, :topic_id, :force do |t,args|
    force = args[:force] == nil ? true : false
    Log.debug(format('Running bias engine on topic: %s', args[:topic_id]))
    topic = Misty::Dyn.get_topic_by_id( args[:topic_id] )

    be = Misty::BiasEngine.new
    be.compile()

    topic.get_articles.each do |article|
      sum = article.get_summary_analysis( false )
      next if sum['syntax'].size == 0 || sum['entities'].size == 0
      Log.debug(format('Running bias engine on article: %s', article.article_id))
      be.converge( sum['syntax']['tokens'], sum['entities'] )
    end
  end

  desc "Create subject importance map"
  task :create_sim, :topic_id do |t,args|
    Log.debug(format('Analyizing entities for topic: %s', args[:topic_id]))
    topic = Misty::Dyn.get_topic_by_id( args[:topic_id] )
    message = {
      'topic_id' => args[:topic_id]
    }
    SQSClient.send_message(
      queue_url: format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_create_sim', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME']),
      message_body: message.to_json
    )
  end

  desc "Scrape"
  task :scrape, :key, :long do |t,args|
    long_timer = true if args[:long] != nil

    topic = Misty::Dyn::get_topic_by_id( args[:key] )
    url = topic.scrape_url
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
      message = {
        'url' => article_url,
        'topic_id' => args[:key]
      }
      SQSClient.send_message(
        queue_url: format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_article_scan', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME']),
        message_body: message.to_json
      )

    end

  end

end

namespace :topics do
  desc "Summarize language"
  task :lang, :force do |t,args|
    force = args[:force] == nil ? true : false
    Log.debug(format('Force: %s', force))
    topics = Misty::Dyn::get_topics( false )
    topics.each do |topic|
      Log.debug(format('Running language analysis on topic: %s', topic.topic_id))
      topic.get_articles.each do |article|
        article.analyze_language( force )
      end
    end
  end

  desc "Create occurance mapping"
  task :create_om do |t,args|
    topics = Misty::Dyn::get_topics( false )
    topics.each do |topic|
      Log.debug(format('Creating OM jobs for topic: %s', topic.topic_id))
      message = { 'topic_id' => topic.topic_id }
      SQSClient.send_message(
        queue_url: format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_create_om', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME']),
        message_body: message.to_json
      )
    end
  end

  desc 'Create subject importance map'
  task :create_sim do |t,args|
    topics = Misty::Dyn::get_topics( false )
    topics.each do |topic|
      message = {
        'topic_id' => topic.topic_id
      }
      SQSClient.send_message(
        queue_url: format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_create_sim', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME']),
        message_body: message.to_json
      )
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
    topics.sort{|a,b| b.created_ts <=> a.created_ts }.each do |topic|
			url = topic.scrape_url
      next if url == nil

    	cache_key = format('url_%s', Digest::SHA1.hexdigest( url ))
      Log.debug(format('Getting topic article list: %s (%s)', url, topic.topic_id))
    	data = Cache.cached( cache_key ) do
      	r = RestClient.get( url )
      	r.body
    	end
    	page = Nokogiri::HTML( data )
	
    	cwiz = page.css("//a[@class=GUyHaf]")
    	cwiz.each do |wiz|
      	article_url = wiz.attributes['href'].value
        message = {
          'url' => article_url,
          'topic_id' => topic.topic_id
        }
        SQSClient.send_message(
          queue_url: format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_article_scan', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME']),
          message_body: message.to_json
        )
    	end
      Misty::nap( 'Putting jobs into SQS' )
		end

  end
end

