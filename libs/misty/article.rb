require 'time'

module Misty

  ARTICLE_MAP = {
    'template' => {
      'body' => '',
      'title' => '',
      'authors' => '',
      'update_time' => ''
    },

    'www.theguardian.com' => {
      'body' => '//div[@itemprop=articleBody]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=name]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'finance.yahoo.com' => {
      'body' => '//article[@itemprop=articleBody]/div/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//a[@itemprop=name]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'abcnews.go.com' => {
      'body' => 'div[@class=article-copy]/p',
      'title' => '//header[@class=article-header]/h1',
      #'authors' => '', ## junk spans
      'update_time' => '//span[@class=timestamp]'
    },

    'www.outsidethebeltway.com' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//h1[@class=entry-title]',
      'authors' => '//span[@class="author vcard"]/a' 
      #'update_time' => ''  ## garbage
    },

    'blog.gainesvillecoins.com' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//h1[@class=entry-title]',
      'authors' => '//p[@class=authordate]/a'
      # 'update_time' => '' ## needs work, might be possible
    },

    'www.latimes.com' => {
      'disabled' => true, ## fuck this site.
      #'body' => '//div[class=lb-card-body]/div/p',
      #'body' => '//div[@class*=lb-widget-text]/p',
      'title' => '//h2[@itemprop=headline]',
      'authors' => '//a[@itemprop=author]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'www.businessinsider.com' => {
      'body' => '//div[@class*=post-content]/p',
      'title' => '//div[@class=sl-layout-post]/h1',
      'authors' => '//li[@class=single-author]/a',
      'update_time' => '//span[@data-bi-format=date]'
    },

    'www.npr.org' => {
      'body' => '//div[@id=storytext]/p',
      'title' => '//div[@class=storytitle]/h1',
      'authors' => '//div[@class=byline-container--block]/div',
      'update_time' => '//time'
    },

    'www.chicagotribune.com' => {
      'body' => '//div[@itemprop=articleBody]/div/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=author]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'www.scmagazine.com' => {
      'body' => '//div[@class=article-body]/div',
      'title' => '//article/h1[@class=title]',
      # 'authors' => '',  ## needs processing work
      'update_time' => '//article/time'
    },

    'www.mediaite.com' => {
      'body' => '//div[@id=post-body]/p',
      'title' => '//div[@id=post-heading]/h3',
      'authors' => '//div[@id=post-heading]/div[@class=dateline]/a'
      ## 'update_time' => '' ## garbage content for datetime
    },

    'www.cnbc.com' => { ## research HUD items as li's
      'body' => '//div[@itemprop=articleBody]/p',
      'title' => '//div[@class=story-top]',
      'authors' => '//div[@itemprop=author]/a',
      'update_time' => '//time[@itemprop=dateUpdated]'  
    },

    'www.eenews.net' => {
      'body' => '//section[@class=content]/p',
      'title' => '//h1[@class=headline]',
      'authors' => '//p[@class=authors]/a',
      'update_time' => '//section[@class=byline]/time'
    },

    'talkingpointsmemo.com' => {
      'body' => '//div[@id=feature-content]/p',
      'title' => '//div[@class*=FeatureTitle]/h1',
      'authors' => '//a[@class*=author]'
      # 'update_time' => '' ## garbage spans for date/time
    },

    'www.washingtonexaminer.com' => {
      'body' => '//section[@class=article-body]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//a[@itemprop=author]/span[@itemprop=name]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'www.nydailynews.com' => {
      'body' => '//article[@itemprop=articleBody]/p',
      'title' => '//h1[@id=ra-headline]',
      'authors' => '//div[@itemprop=author]/a[@itemprop=name]',
      'subtitle' => '//h2[@itemprop=description]',
      'update_time' => '//div[@itemprop=datePublished]'
    },

    'thehill.com' => {
      'body' => '//div[@class*=field-item]/p',
      'title' => '//h1[@class=title]',
      'authors' => '//span[@class=submitted-by]/a',
      'update_time' => '//span[@class=submitted-date]'
    },

    'www.cnn.com' => {
      'body' => '//div[@class=zn-body__paragraph]',
      'title' => '//h1[@class=pg-headline]',
      'authors' => '//span[@class=metadata__byline__author]/a',
      'update_time' => '//p[@class=update-time]'
    },
    'www.theroot.com' => {
      'body' => '//div[@class*=post-content]/p',
      'title' => '//h1[@class*=headline]',
      'authors' => '//div[@class*=meta__byline]/a',
      'update_time' => '//time[@class*=meta__time]'
    },
    'www.breitbart.com' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//header/h1',
      'authors' => '//span[@class=by-author]/a',
      'update_time' => '//span[@class=bydate]'
    },
    'www.washingtonpost.com' => {
      'body' => '//article[@itemprop=articleBody]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=author]/a/span[@itemprop=name]',
      'subtitle' => '//h2[@class=headline__subtitle]'
    }
  }

  class Article
    @uri
    @url

    @source
    @article
    @topic_id
    @article_id

    @score
    @magnitude

    def initialize( topic_id, url )
      @uri = URI( url )
      @url = url

      @topic_id = topic_id

      @article_id = Digest::SHA1.hexdigest( url )
      Log.debug(format('article_id: %s', @article_id))

      @article = {}
    end

    def get_page
      Log.debug('Getting page')
      data = Cache.cached(format( 'url_%s', @article_id )) do
        begin
          r = RestClient.get( @url )
          r.body
        rescue RestClient::RangeNotSatisfiable => e
          Log.fatal('Failed to get page'.red)
        end
      end
      Nokogiri::HTML( data )
    end

    def get_article_file( topic_key, article_key)
      article_dir = File.join( '/mnt', 'data', 'cache', 'articles', topic_key )
      FileUtils.mkdir_p article_dir if !File.exists? article_dir
      File.open( File.join( article_dir, format( '%s.json', article_key )), 'w' )
    end

    def save
      doc = {
        'url' => @url,
        'score' => @score,
        'source' => @uri.host,
        'article' => @article,
        'topic_id' => @topic_id,
        'magnitude' => @magnitude,
        'article_id' => @article_id
      }

      f = get_article_file( @topic_id, @article_id )
      f.puts doc.to_json
      f.close

      Dyn::save_article( doc )
      flush_dyn

      Log.debug('Sleeping after article save.')
      sleep rand(10)
    end

    def flush
      flush_dyn
      flush_page
    end

    def flush_page
      Cache.del_key(format( 'url_%s', @article_id ))
    end

    def flush_dyn
      dyn_key = format( 'article_%s_%s', ENV['MISTY_ENV_NAME'], @article_id )
      Log.debug(format('dyn_key: %s', dyn_key))
      Cache.del_key( dyn_key )
    end

    def handle_elements( type, elements )
      case type
      when 'body'
        @article['body'] = elements.map{|el| { 
          'body' => el.text,
          'digest' => Digest::SHA1.hexdigest( el.text )
        } if el.text != "" && el.text != " "}.compact

      when 'title'
        @article['title'] = elements.first.text

      when 'authors'
        @article['authors'] = elements.map{|el| el.text }

      when 'update_time'
        if elements.first.name == 'time'
          if elements.first.attributes.has_key?( 'datetime' )
            updated = elements.first.attributes['datetime'].value
          else
            updated = elements.first.text
          end
        elsif elements.first.name == 'span' && elements.first.attributes.has_key?( 'rel' )
          updated = elements.first.attributes['rel']
        else
          updated = elements.first.text
        end

        Log.debug(format('Updated: %s', updated))

        begin
          ts = Time.parse( updated )
          @article['update_time'] = ts.to_f

        rescue => e
          Log.fatal(format('Unable to parse time field: %s', e))

        end

      else
        Log.fatal(format('Unable to handle elements for: %s', type))

      end
    end

    def process_page
      xml = get_page
      if Misty::ARTICLE_MAP.has_key?( @uri.host )
        return nil if Misty::ARTICLE_MAP[@uri.host].has_key?( 'disabled' ) && Misty::ARTICLE_MAP[@uri.host]['disabled'] == true
        Log.debug(format('Processing: %s', @uri.host))
        m = Misty::ARTICLE_MAP[@uri.host]
        m.each do |name, selector|
          Log.debug(format('Xpath selector for %s: %s', name, selector))
          elements = xml.css selector
          Log.debug(format('Found %i elements', elements.size))
          handle_elements( name, elements )
        end

      else
        Log.fatal(format('Unknown article processor for domain: %s', @uri.host).red)

      end
    end

		def analyze( topic, line )
      # Log.debug(format('Running analisis for %s', line))
  		cache_key = format('ml_%s_%s', topic, Digest::SHA1.hexdigest( line ))
  		Cache.cached_json( cache_key ) do
    		encoded = line.to_ascii.gsub( /"/, "'" )
    		cmd_ml = format('gcloud ml language analyze-%s --content="%s"', topic, encoded)
    		Log.debug('CMD(ml): %s' % cmd_ml)
    		res = `#{cmd_ml}`
    		if res.match( /ERROR/ )
      		Log.fatal("Unable to parse because of some stupid ass bullshit.")
      		exit
      		res = {}
    		end
    		sleep 0.2
    		res
  		end
		end

    def analyze_language
      return nil if @article['body'] == nil

      Log.debug(format('Running language analyisis on %s', @article_id))

      @article['body'].each do |body_el|
        digest = Digest::SHA1.hexdigest( body_el['body'] )
        doc = { 
          'digest' => digest,
          'article_id' => @article_id, 
          'article_id_digest' => format( '%s-%s', @article_id, digest )
        }

        doc['syntax'] = analyze( 'syntax', body_el['body'] )
        doc['entities'] = analyze( 'entities', body_el['body'] )
        doc['sentiment'] = analyze( 'sentiment', body_el['body'] )

        #Dyn::save_article_analysis( doc )
        #Log.debug('Sleeping')
        #sleep rand(10)

        body_el['sentiment'] = doc['sentiment']['documentSentiment']
      end

      entire_body = @article['body'].map{|b| b['body'] }.join( ' ' )
      sentiment = analyze( 'sentiment', entire_body )
      #pp syntax

      @score = sentiment['documentSentiment']['score']
      @magnitude = sentiment['documentSentiment']['magnitude']

      # save
    end

  end
end
