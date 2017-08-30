require 'pp'
require 'json'
require 'logger'
require 'aws-sdk'
require 'net/http'
require 'nokogiri'
require 'fileutils'
require 'digest/sha1'

require './libs/cache.rb'

Log = Logger.new(STDOUT)
Cache = DevOps::Cache.new

desc 'Create an article event key'
task :mk_event_key, :event_name do |t,args|
  creds = Aws::SharedCredentials.new()
  d_client = Aws::DynamoDB::Client.new(credentials: creds)

  d_client.put_item({
    item: {
      topic_id: Digest::SHA1.hexdigest( args[:event_name] ),
      topic_name: args[:event_name]
    },
    table_name: 'misty_dev_topics'
  })
end

def get_article_file( article_event_key, url_cache_key )
  article_dir = File.join( 'data', 'articles', article_event_key )
  FileUtils.mkdir_p article_dir if !File.exists? article_dir

  File.open( File.join( article_dir, format( '%s.json', url_cache_key )), 'w' )
end

namespace :grab do

  desc "Grab bb article"
  task :article, :key, :url do |t,args|
    Log.debug('Key: %s' % args[:key]) 
    Log.debug('URL: %s' % args[:url]) 

    uri = URI( args[:url] )

    cache_key = Digest::SHA1.hexdigest( args[:url] )
    data = Cache.cached( cache_key ) do
      Net::HTTP.get( uri )
    end

    page = Nokogiri::HTML( data )

    h = Hash.new()
    h['url'] = args[:url]
    h['source'] = uri.host
    h['article'] = Hash.new()
    h['topic_id'] = args[:key]
    h['article_id'] = cache_key

    case uri.host
    when 'www.cnn.com'
      proc_cnn( page, h )

    when 'www.breitbart.com'
      proc_breitbart( page, h )

    when 'www.huffingtonpost.com'
      proc_huffpo( page, h )

    else
      Log.fatal( 'Unknown handler for: %s' % uri.host )

    end

    f = get_article_file( args[:key], cache_key )
    f.puts h.to_json
    f.close

    Log.debug('File: %s' % f.path)

    creds = Aws::SharedCredentials.new()
    d_client = Aws::DynamoDB::Client.new(credentials: creds)

    d_client.put_item({
      item: h,
      table_name: 'misty_dev_articles'
    })

  end
end

def proc_huffpo( page, h )
  paragraphs = []
  title = page.css('//h1[@class=headline__title]').children.first.text
  h['article']['title'] = title

  sub_title = page.css('//h2[@class=headline__subtitle]').children.first.text
  paragraphs.push sub_title

  find = page.css("div[class*='text']/p")
  paragraphs.push( find.map{|f| f.children.first.text } ).flatten!

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

  h['article']['body'] = paragraphs.compact
end
