require 'pp'
require 'json'
require 'logger'
require 'net/http'
require 'nokogiri'
require 'fileutils'
require 'digest/sha1'

require './libs/cache.rb'

Log = Logger.new(STDOUT)
Cache = DevOps::Cache.new

desc "Create an article event key"
task :mk_event_key, :event_name do |t,args|
  event_key = Digest::SHA1.hexdigest( args[:event_name] )
  Log.info('EventKey: %s' % event_key)
end

def get_article_file( source, article_event_key, url_cache_key )
  article_dir = File.join( 'data', 'articles', article_event_key )
  FileUtils.mkdir_p article_dir if !File.exists? article_dir

  File.open( File.join( article_dir, format( '%s.json', url_cache_key )), 'w' )
end

namespace :grab do

  desc "Grab CNN article"
  task :cnn, :key, :url do |t,args|
    Log.debug('Key: %s' % args[:key]) 
    Log.debug('URL: %s' % args[:url]) 

    cache_key = Digest::SHA1.hexdigest( args[:url] )
    data = Cache.cached( cache_key ) do
      uri = URI( args[:url] )
      Net::HTTP.get( uri )
    end

    page = Nokogiri::HTML( data )

    title = page.css('h1[class=pg-headline]').children[0].text

    paragraphs = []

    ## First paragraph.
    find = page.xpath("//p[@class='zn-body__paragraph speakable']")
    paragraphs.push find.first.children[1].text

    ## Next few paragarphs.
    find = page.xpath("//div[@class='zn-body__paragraph speakable']")
    paragraphs.push( find.map{|f| f.children.first.text } ).flatten!

    ## Everything else
    find = page.xpath("//div[@class='zn-body__paragraph']")
    paragraphs.push( find.map{|f| f.children.first.text } ).flatten!

    f = get_article_file( 'CNN', args[:key], cache_key )

    h = Hash.new()
    h['url'] = args[:url]
    h['source'] = "CNN"
    h['article_key'] = args[:key]
    h['article'] = Hash.new()

    h['article']['title'] = title
    h['article']['body'] = paragraphs.join()

    f.puts h.to_json
    f.close

  end
end
