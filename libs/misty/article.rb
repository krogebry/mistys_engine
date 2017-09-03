require 'time'

module Misty

  class Article
    @uri
    @url

    @data

    @source
    @topic_id
    @article_id

    @score
    @magnitude

    attr_accessor :article_id, :source, :magnitude, :score, :article, :data, :url
    #def initialize( topic_id, url )
    def initialize( data=nil )
      if data != nil
        self.load( data )
      end
    end

    def load( data )
      if data.class == Hash
        @data = data
      else
        @data = Misty::Dyn::get_article_by_id( data )
      end

      if @data == nil ## nothing to load
        @data = { 'article' => {} }
        return nil
      end

      @url = @data['url'] if @data.has_key?('url')
      @uri = URI( @data['url'] ) if @data['url'] != nil

      @source = @data['source'] if @data.has_key?('source')
      @data_id = @data['data_id'] if @data.has_key?('data_id')

      @topic_id = @data['topic_id'] if @data.has_key?('topic_id')
      @article_id = @data['article_id']

      @score = @data['score'].to_f if @data.has_key?('score')
      @magnitude = @data['magnitude'].to_f if @data.has_key?('magnitude')
    end

    def get_body
      @data['article']['body']
    end

    def has_body?
      @data['article'].has_key?( 'body' )
    end

    def has_summary?
      @data.has_key?( 'summary' )
    end

    def get_summary
      @data['summary']
    end

    def get_headers
      {
        'accept': "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
        'user-agent': "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36",
        'accept-language': "en-US,en;q=0.8"
      }
    end

    def get_page( url )
      Log.debug('Getting page: %s' % url)
      data = Cache.cached(format( 'url_%s', @article_id )) do
        begin
          headers = get_headers
          #r = RestClient.get( url, :headers => headers, :verify_ssl => false )
          r = RestClient::Request.execute(method: :get, url: url, headers: headers, verify_ssl: false)
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

    def save( write_to_dyn=false )
      doc = {
        'url' => @url,
        'score' => @score,
        'source' => @uri.host,
        'topic_id' => @topic_id,
        'magnitude' => @magnitude,
        'article_id' => @article_id
      }
      doc['article'] = @data['article'] if @data.has_key?( 'article' )

      f = get_article_file( @topic_id, @article_id )
      f.puts doc.to_json
      f.close

      if write_to_dyn == true
        Dyn::save_article( doc )
        Misty::nap( 'article save' )

        Dyn::get_article_by_id( @article_id, true )
        Misty::nap( 'refreshing cache for article' )
      end
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
        @data['article']['body'] = elements.map{|el| { 
          'body' => el.text,
          'digest' => Digest::SHA1.hexdigest( el.text )
        } if el.text != "" && el.text != " "}.compact

      when 'title'
        @data['article']['title'] = elements.first.text

      when 'authors'
        @data['article']['authors'] = elements.map{|el| el.text if el.text != ""}.compact

      when 'pushlished_time'
        ts = process_time( elements )
        Log.debug(format('Published: %s', ts))
        @data['article']['published_time'] = ts.to_f

      when 'update_time'
        ts = process_time( elements )
        Log.debug(format('Updated: %s', ts))
        @data['article']['update_time'] = ts.to_f

      else
        Log.fatal(format('Unable to handle elements for: %s', type))

      end
    end

    def process_time( elements )
      if elements.first.name == 'time'
        if elements.first.attributes.has_key?( 'unixtime' )
          ts = Time.at( elements.first.attributes['unixtime'].value.to_f )

        elsif elements.first.attributes.has_key?( 'datetime' )
          begin
            ts = Time.parse( elements.first.attributes['datetime'].value )
          rescue => e
          end

        else
          ts = Time.parse( elements.first.text )

        end

      elsif elements.first.name == 'span' && elements.first.attributes.has_key?( 'rel' )
        #pp elements.first.attributes
        #ts = Time.parse( elements.first.attributes['rel'].value )
        ts = Time.at( elements.first.attributes['rel'].value.to_f )

      elsif elements.first.name == 'meta'
        ts = Time.parse( elements.first.attributes['content'] )

      else
        begin
          ts = Time.parse( elements.first.text )
        rescue => e
          Log.fatal(format('Unable to time parse string: %s', elements.first.text).red)
          return nil
        end

      end

      ts
    end

    def process_page( url, topic_id=nil )
      @uri = URI( url )
      @url = url

      return false if BROKEN_SITES.include?( @uri.host )

      @topic_id = topic_id if topic_id != nil
      @article_id = Digest::SHA1.hexdigest( url ) 

      self.load( @article_id )
      Log.debug(format('Processing page article_id: %s | topic_id: %s', @article_id, @topic_id))

      xml = get_page( url )
      # return nil if Misty::SOURCES_MAP[@uri.host].has_key?( 'disabled' ) && Misty::SOURCES_MAP[@uri.host]['disabled'] == true

      if Misty::SOURCES_MAP.has_key?( @uri.host )
        m = Misty::SOURCES_MAP[@uri.host]
        return false if m['disabled'] == true

      else
        ## check for generator
        generator_el = xml.css( '//meta[@name=generator]' )
        if generator_el != nil && generator_el.size > 0
          generator = generator_el.first.attributes['content'].to_s
          Log.debug(format('Found generator tag: %s', generator).green)

          if generator.match( /Drupal 7/ )
            m = Misty::DRUPAL_7

          elsif generator.match( /WordPress\s4\.8\.1/ )
            m = Misty::WORDPRESS_481

          elsif generator.match( /WordPress/ )
            m = Misty::WORDPRESS

          else
            Log.fatal(format('Unknown generator: %s', generator_el ).red)
            return false

          end
        else
          Log.fatal(format('Unable to find generator').red)
          return false

        end
      end

      published_el = xml.css( "//meta[@property='article:published_time']" )
      if published_el.size > 0
        ts = process_time( published_el )
        if ts 
          Log.debug(format('Published: %s', ts))
          @data['article']['published_time'] = ts.to_f
        end
      end

      modified_el = xml.css( "//meta[@property='article:modified_time']" )
      if modified_el.size > 0
        ts = process_time( modified_el )
        if ts
          Log.debug(format('Modified: %s', ts))
          @data['article']['modified_time'] = ts.to_f
        end
      end

      Log.debug(format('Processing: %s', @uri.host))
      m.each do |name, selector|
        Log.debug(format('Xpath selector for %s: %s', name, selector))
        elements = xml.css selector
        Log.debug(format('Found %i elements', elements.size))
        if elements.size > 0
          handle_elements( name, elements )
        end
      end

      return true
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
        Misty::nap( 'after calling analyze' )
    		res
  		end
		end

    def analyze_language( force=false )
      return false if !has_body?

      Log.debug(format('Running language analyisis on %s', @article_id))

      get_body.each do |body_el|
        digest = Digest::SHA1.hexdigest( body_el['body'] )
        analysis = Dyn::get_article_analysis( @article_id, digest )

        if @score == nil
          Log.debug('Score is nil')
          if analyze_language_body
            save
            flush_dyn
          end
        end

        next if analysis != nil 

        doc = { 
          'digest' => digest,
          'article_id' => @article_id, 
          'article_id_digest' => format( '%s-%s', @article_id, digest )
        }

        doc['syntax'] = analyze( 'syntax', body_el['body'] )
        doc['entities'] = analyze( 'entities', body_el['body'] )
        doc['sentiment'] = analyze( 'sentiment', body_el['body'] )

        body_el['sentiment'] = doc['sentiment']['documentSentiment']

        Dyn::save_article_analysis( doc )
        Misty::nap( 'saving article analysis' )

        analysis = Dyn::get_article_analysis( @article_id, digest, true )
        Misty::nap( 'refreshing language analysis' )
      end
    end

    def analyze_language_body
      return false if !has_body?
      entire_body = get_body.map{|b| b['body'] }.join( ' ' )
      sentiment = analyze( 'sentiment', entire_body )
      @score = sentiment['documentSentiment']['score']
      @magnitude = sentiment['documentSentiment']['magnitude']
    end

  end
end
