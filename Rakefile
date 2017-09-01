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

desc 'Create an article event key'
task :mk_event_key, :event_name do |t,args|
  DynamoClient.put_item({
    item: {
      topic_id: Digest::SHA1.hexdigest( args[:event_name] ),
      topic_name: args[:event_name]
    },
    table_name: 'misty_dev_topics'
  })
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
    topic = Misty::Topic.new( args[:topic_id] )
    topic.summarize
    topic.save
  end
end

namespace :article do

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

  desc "Grab an article"
  task :grab, :key, :url do |t,args|
    Log.debug('Key: %s' % args[:key]) 
    Log.debug('URL: %s' % args[:url]) 

    #uri = URI( args[:url] )

    article = Misty::Article.new( args[:key], args[:url] )
    # article.flush
    article.process_page
    article.analyze_language
    article.save

    case false
    when 'www.huffingtonpost.com'
      proc_huffpo( page, h )

    when 'nypost.com'
      proc_nypost( page, h )

    when 'www.sfgate.com'
      proc_sfgate( page, h )

    when 'www.nbcnews.com'
      proc_nbcnews( page, h )

    when 'fox40.com'
      proc_fox40( page, h )

    when 'people.com'
      proc_people( page, h )

    when 'sacramento.cbslocal.com'
      proc_sacramento_cbslocal_com( page, h )

    when 'sanfrancisco.cbslocal.com'
      proc_sanfrancisco_cbslocal_com( page, h )

    when 'host.madison.com'
      proc_host_madison_com( page, h )

    when 'www.dailymail.co.uk'
      proc_dailymail_co_uk( page, h )

    when 'abcnews.go.com'
      proc_abcnews_go( page, h )

    when 'www.sacbee.com'
      proc_sacbee( page, h )

    when 'www.abc10.com'
      proc_abc10( page, h )

    when 'www.kcra.com'
      proc_kcra( page, h )

    when 'www.greenwichtime.com'
      proc_greenwichtime_com( page, h )

    when 'www.eastbaytimes.com'
      proc_eastbaytimes( page, h )

    when 'www.turnto23.com'
      proc_turnto23( page, h )

    when 'www.washingtonpost.com'
      proc_www_washingtonpost( page, h )

    when 'www.nydailynews.com'
      proc_nydailynews( page, h )

    when 'www.theroot.com'
      proc_theroot( page, h )

    when 'talkingpointsmemo.com'
      proc_talkingpointsmemo( page, h )

    when 'www.eenews.net'
      proc_eenews( page, h )

    #else
      #Log.fatal( 'Unknown handler for: %s' % uri.host )
      #exit

    end

    #f = get_article_file( args[:key], cache_key )
    #f.puts h.to_json
    #f.close

    #Log.debug('File: %s' % f.path)

		# save_article h
    # sleep 10
  end
end

def proc_eenews( page, h )
  paragraphs = []
  title = page.css('//h1[@class=headline]').children.first.text
  h['article']['title'] = title
  find = page.css("//section[@class=content]/p")
  paragraphs.push( find.map{|f| f.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_talkingpointsmemo( page, h )
  paragraphs = []
  title = page.css('//div[@class*=FeatureTitle]/h1').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@id=feature-content]/p")
  paragraphs.push( find.map{|f| f.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_theroot( page, h )
  paragraphs = []
  title = page.css('//h1[@class*=headline]').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@class*=post-content]/p")
  paragraphs.push( find.map{|f| f.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_nydailynews( page, h )
  paragraphs = []
  title = page.css('//h1[@id=ra-headline]').children.first.text
  h['article']['title'] = title
  find = page.css("//article[@itemprop=articleBody]/p")
  paragraphs.push( find.map{|f| f.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_www_washingtonpost( page, h )
  paragraphs = []
  title = page.css('//h1[@itemprop=headline]').children.first.text
  h['article']['title'] = title
  find = page.css("//article[@itemprop=articleBody]/p")
  paragraphs.push( find.map{|f| f.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_turnto23( page, h )
  paragraphs = []
  title = page.css('//h1[@class=headline]').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@class*=story__content__body]/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_eastbaytimes( page, h )
  paragraphs = []
  title = page.css('//span[@class*=dfm-title]').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@class=body-copy]/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_greenwichtime_com( page, h )
  paragraphs = []
  title = page.css('//h1[@class*=entry-title]').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@class=article-body]/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_kcra( page, h )
  paragraphs = []
  title = page.css('//h1[@class=article-headline--title]').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@class=article-content--body-text]/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_abc10( page, h )
  paragraphs = []
  title = page.css('//h1[@class=asset-headline]').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@itemprop=articleBody]/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_sacbee( page, h )
  paragraphs = []
  title = page.css('//h3[@class=title]').children.first.text
  h['article']['title'] = title
  find = page.css("//div[@class=content-body-]/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_abcnews_go( page, h )
  paragraphs = []
  title = page.css('//header[@class=article-header]/h1').children.first.text
  h['article']['title'] = title
  find = page.css("div[@class='article-copy']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_dailymail_co_uk( page, h )
  paragraphs = []
  title = page.css('//div[@id=js-article-text]/h1').children.first.text
  h['article']['title'] = title
  find = page.css("div[@itemprop='articleBody']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != "" && p != " "}
  h['article']['body'] = paragraphs.compact
end

def proc_host_madison_com( page, h )
  paragraphs = []
  title = page.css('//h1[@class=headline]/span').children.first.text
  h['article']['title'] = title
  find = page.css("div[class='subscriber-preview']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != ""}
  h['article']['body'] = paragraphs.compact
end

def proc_sanfrancisco_cbslocal_com( page, h )
  paragraphs = []
  title = page.css('//h1[@class=posttitle]').children.first.text
  h['article']['title'] = title
  find = page.css("div[class='story']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != ""}
  h['article']['body'] = paragraphs.compact
end

def proc_sacramento_cbslocal_com( page, h )
  paragraphs = []
  title = page.css('//h1[@class=posttitle]').children.first.text
  h['article']['title'] = title
  find = page.css("div[class='story']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p } if p != ""}
  h['article']['body'] = paragraphs.compact
end

def proc_people( page, h )
  paragraphs = []
  title = page.css('//h1[@class=article-header__title]').children.first.text
  h['article']['title'] = title
  find = page.css("div[class='article-body__inner']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p }}
  h['article']['body'] = paragraphs.compact
end

def proc_fox40( page, h )
  paragraphs = []
  title = page.css('//h1[class=entry-title]').children.first.text
  h['article']['title'] = title
  find = page.css("div[class='entry-content']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p }}
  h['article']['body'] = paragraphs.compact
end

def proc_nbcnews( page, h )
  paragraphs = []

  title = page.css('//div[@class=article-hed]/h1').children.first.text
  h['article']['title'] = title

  find = page.css("div[class='article-body']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p }}

  h['article']['body'] = paragraphs.compact
end

def proc_sfgate( page, h )
  paragraphs = []
  title = page.css('//div[@class=article-title]/h1').children.first.text
  h['article']['title'] = title

  find = page.css("div[class='article-body']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p }}

  h['article']['body'] = paragraphs.compact
end

def proc_nypost( page, h )
  paragraphs = []
  title = page.css('//div[@class=article-header]/h1/a').children.first.text
  h['article']['title'] = title

  find = page.css("div[class*='entry-content']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!
	paragraphs.map!{|p| { body: p }}

  h['article']['body'] = paragraphs.compact
end

def proc_huffpo( page, h )
  paragraphs = []
  title = page.css('//h1[@class=headline__title]').children.first.text
  h['article']['title'] = title

  sub_title = page.css('//h2[@class=headline__subtitle]').children.first.text
  paragraphs.push sub_title

  find = page.css("div[class*='text']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!

	paragraphs.map!{|p| { body: p }}

  h['article']['body'] = paragraphs.compact
end

def proc_breitbart( page, h )
  paragraphs = []
  title = page.css('//header/h1').children.first.text
  h['article']['title'] = title

  find = page.css('//div[@class=entry-content]/h2')
  paragraphs.push find.children.first.text

  find = page.css('//div[@class=entry-content]/p')
  paragraphs.push( find.map{|f| f.children.first.text }.select{|t| t != '' }).flatten!

	paragraphs.map!{|p| { body: p }}

  h['article']['body'] = paragraphs.compact
end

def proc_cnn( page, h )
  paragraphs = []

  title = page.css('h1[class=pg-headline]').children.first.text
  h['article']['title'] = title

  ## First paragraph.
  find = page.xpath("//p[@class='zn-body__paragraph speakable']")
  paragraphs.push find.first.children[1].text

  ## Next few paragarphs.
  find = page.xpath("//div[@class='zn-body__paragraph speakable']")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!

  ## Everything else
  find = page.xpath("//div[@class='zn-body__paragraph']")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!

	paragraphs.map!{|p| { body: p }}

  h['article']['body'] = paragraphs.compact
end
