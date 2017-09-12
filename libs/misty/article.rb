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

    attr_accessor :article_id, :source, :magnitude, :score, :article, :data, :url, :topic_id
    #def initialize( topic_id, url )
    def initialize( data=nil )
      self.load( data )
    end

    def self.get_by_url( url )
      article_id = Digest::SHA1.hexdigest( url ) 
      Dyn::get_article_by_id( article_id, false )
    end

    def load( data )
      # Log.debug('Loading article')
      @data = data

      if @data == nil ## nothing to load
        @data = { 'article' => {} }
        return true
      end

      @url = @data['url'] 
      if !@data.has_key?( 'url' ) || @url == nil
        Log.fatal(format('Unable to find url for article: %s', @data['article_id']).red)
        exit
      end
      @uri = URI( @url )

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

    def get_host
      uri = if @uri == nil
        URI( @url )
      else
        @uri
      end
      uri.host
    end

    def add_bias( digest, bias )
      line = get_body.select{|b| b['digest'] == digest }.first
      line['bias'] ||= []
      line['bias'].push( bias )
      save( true )
    end

    def get_biases
      bias_list = {}
      get_body.select{|b| b.has_key?( 'bias' )}.each do |l|
        l['bias'].each do |bias|
          bias_list[bias] ||= 0
          bias_list[bias] += 1
        end
      end
      bias_list
    end

    def rm_biases
      get_body.select{|b| b.has_key?( 'bias' )}.each do |l|
        l['bias'] = []
      end
      save( true )
    end

    def get_entire_body
      str = get_body.map{|b| b['body'] }.join( ' ' )
      str.gsub!( /\t/, '' )
      str.gsub!( /\r\n/, '')
      str.gsub!( /#{[0x201D].pack("U")}/, '"' )
      str.gsub!( /#{[0x201C].pack("U")}/, '"' )
      str
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

    def get_title
      @data['article']['title']
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

        rescue RestClient::InternalServerError => e
          Log.fatal(format('Failed to get page: %s', e).red)
          nil

        rescue RestClient::MovedPermanently => e
          Log.fatal(format('Failed to get page: %s', e).red)
          nil

        rescue RestClient::Exceptions::ReadTimeout => e
          Log.fatal(format('Failed to get page: %s', e).red)
          nil

        rescue RestClient::NotFound => e
          Log.fatal(format('Failed to get page: %s', e).red)
          nil

        rescue RestClient::ServiceUnavailable => e
          Log.fatal(format('Failed to get page: %s', e).red)
          nil

        rescue RestClient::RangeNotSatisfiable => e
          Log.fatal(format('Failed to get page: %s', e).red)
          nil

        end
      end

      if data != nil
        return Nokogiri::HTML( data )
      else
        return nil
      end
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
        Dyn::get_article_by_id( @article_id, true )
      end
    end

    def flush_page
      Cache.del_key(format( 'url_%s', @article_id ))
    end

    def get_title
      if @data['article'].has_key?( 'title' ) && @data['article']['title'] != nil 
        @data['article']['title'][0,100]
      else
        "BLANK TITLE"
      end
    end

    def flush_dyn
      dyn_key = format( 'article_%s_%s', ENV['MISTY_ENV_NAME'], @article_id )
      Log.debug(format('dyn_key: %s', dyn_key))
      Cache.del_key( dyn_key )
    end

    def handle_body_elements( elements )
      @data['article']['body'] ||= []
      if @data['article']['body'].size == 0
        @data['article']['body'] = elements.map{|el| { 
          'body' => el.text,
          'digest' => Digest::SHA1.hexdigest( el.text )
        } if el.text != "" && el.text != " "}.compact
      end
    end

    def handle_elements( type, elements )
      case type
      when 'body'
        handle_body_elements( elements )

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
        ts = Time.at( elements.first.attributes['rel'].value.to_f )

      elsif elements.first.name == 'meta'
        begin
          ts = Time.parse( elements.first.attributes['content'] )
        rescue => e
        end

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
      @url = url
      @uri = URI( url ) if @uri == nil
      return false if BROKEN_SITES.include?( @uri.host )

      @topic_id = topic_id if @topic_id == nil
      @article_id = Digest::SHA1.hexdigest( url ) if @article_id == nil ## loading for the first time

      Log.debug(format('Processing page article_id: %s | topic_id: %s', @article_id, @topic_id))

      xml = get_page( url )
      return false if xml == nil

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

          elsif generator.match( /WordPress\.com/ )
            m = Misty::WORDPRESS_COM

          elsif generator.match( /WordPress/ )
            m = Misty::WORDPRESS

          else
            Log.fatal(format('Unknown generator: %s', generator_el ).red)
            return false

          end
        else
          Log.fatal(format('Unable to find generator').blue)
          # return false
          m = {}

        end
      end

      m.delete( 'body' ) if get_body_el( xml )
      m.delete( 'title' ) if get_title_el( xml )
      m.delete( 'author' ) if get_author_el( xml )
      m.delete( 'modified_time' ) if get_modified_time_el( xml )
      m.delete( 'published_time' ) if get_published_time_el( xml )

      #pp @data

      Log.debug(format('Processing: %s', @uri.host))
      m.each do |name, selector|
        Log.debug(format('Xpath selector for %s: %s', name, selector))
        elements = xml.css selector
        Log.debug(format('Found %i elements', elements.size))
        if elements.size > 0
          handle_elements( name, elements )
        end
      end

      if !@data['article'].has_key?( 'body' )
        Log.fatal(format('Unable to find body elements: %s | %s', @article_id, @url).red)
        #exit
        return false
      end

      if !@data['article'].has_key?( 'title' ) || @data['article']['title'] == ""
        Log.fatal(format('Unable to find title elements: %s | %s', @article_id, @url).red)
        #exit
        return false
      end

      return true
    end

    def get_published_time_el( xml )
      el = xml.css( "//meta[@property='article:published_time']" )
      if el.size > 0
        Log.debug('Found published time element'.yellow)
        ts = process_time( el )
        if ts 
          Log.debug(format('Published: %s', ts))
          @data['article']['published_time'] = ts.to_f
          return true
        end
      end

      el = xml.css( "//meta[@itemprop=datePublished]" )
      if el.size > 0
        Log.debug('(2) Found published time element'.yellow)
        ts = process_time( el )
        if ts 
          Log.debug(format('Published: %s', ts))
          @data['article']['published_time'] = ts.to_f
          return true
        end
      end

      return false
    end

    def get_modified_time_el( xml )
      el = xml.css( "//meta[@property='article:modified_time']" )
      if el.size > 0
        Log.debug('(1) Found modified time element'.yellow)
        ts = process_time( el )
        if ts
          Log.debug(format('Modified: %s', ts))
          @data['article']['modified_time'] = ts.to_f
          return true
        end
      end
      return false
    end

    def get_author_el( xml )
      el = xml.css( "//meta[@itemprop=author]" )
      if el.size == 1
        Log.debug('(1) Found auhtor element'.yellow)
        @data['article']['authors'] = el.map{|el| el.text if el.text != ""}.compact
        return true
      end

      el = xml.css( "//a[@rel=author]" )
      if el.size == 1
        Log.debug('Found auhtor element'.yellow)
        @data['article']['authors'] = el.map{|el| el.text if el.text != ""}.compact
        return true
      end

      el = xml.css( "//h1[@rel=author]" )
      if el.size == 1
        Log.debug('Found auhtor element'.yellow)
        @data['article']['authors'] = el.map{|el| el.text if el.text != ""}.compact
        return true
      end

      return false
    end

    def get_body_el( xml )
      el = xml.css( "//div[@class*=entry-content]/p" )
      if el.size > 0
        Log.debug(format('(1) Found body elements %i', el.size).yellow)
        handle_body_elements( el )
        return true
      end

      el = xml.css( "//div[@itemprop=articleBody]/p" )
      if el.size > 0
        Log.debug(format('(2) Found body elements %i', el.size).yellow)
        handle_body_elements( el )
        return true
      end

      el = xml.css( "//div[@id=article]/p" )
      if el.size > 0
        Log.debug(format('(3) Found body elements %i', el.size).yellow)
        handle_body_elements( el )
        return true
      end

      el = xml.css( "//section[@class*=entry-content]/p" )
      if el.size > 0
        Log.debug(format('(4) Found body elements %i', el.size).yellow)
        handle_body_elements( el )
        return true
      end

      return false
    end

    def get_title_el( xml )
      el = xml.css( "//meta[@name=description]" )
      if el.size == 1
        Log.debug('(1) Found title'.yellow)
        v = el.first.attributes['content'].value
        if v != ""
          @data['article']['title'] = v
          return true
        end
      end

      el = xml.css( "//meta[@itemprop=description]" )
      if el.size == 1
        Log.debug('(2) Found title'.yellow)
        v = el.first.attributes['content'].value
        if v != ""
          @data['article']['title'] = v
          return true
        end
      end

      el = xml.css( "//h1[@itemprop=headline]" )
      if el.size == 1
        Log.debug('(3) Found title'.yellow)
        @data['article']['title'] = el.first.text
        return true
      end

      el = xml.css( "//h1[@class=entry-title]" )
      if el.size == 1
        Log.debug('(4) Found headline'.yellow)
        @data['article']['title'] = el.first.text
        return true
      end

      el = xml.css( "//title" )
      if el.size == 1
        Log.debug('(5) Found headline'.yellow)
        @data['article']['title'] = el.first.text
        return true
      end

      return false
    end

		def analyze( topic, line, force=false )
      # Log.debug(format('Running analisis for %s', line))
  		cache_key = format('ml_%s_%s', topic, Digest::SHA1.hexdigest( line ))
      Cache.del_key( cache_key ) if force == true
  		Cache.cached_json( cache_key ) do
    		encoded = line.to_ascii.gsub( /"/, "'" )
    		cmd_ml = format('gcloud ml language analyze-%s --content="%s"', topic, encoded)
    		# Log.debug('CMD(ml): %s' % cmd_ml)
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

    def get_summary_analysis( force=false )
      Dyn::get_article_analysis( @article_id, 'ALL_SUMMARY', force )
    end

    def analyze_language( force=false )
      return false if !has_body?

      Log.debug(format('Running language analyisis on article: %s', @article_id))

      summary_analysis = get_summary_analysis
      #Log.debug('Force: %s' % force )
      summary_analysis = nil if force == true

      digest = 'ALL_SUMMARY'
      summary_analysis = {
        'digest' => digest,
        'article_id' => @article_id,
        'article_id_digest' => format( '%s-%s', @article_id, digest )
      } if summary_analysis == nil

      summary_analysis['digest'] = digest if !summary_analysis.has_key?( 'digest' )
      summary_analysis['article_id'] = @article_id if !summary_analysis.has_key?( 'article_id' )

      save_doc = false
      save_summary = false

      if !summary_analysis.has_key?( 'entities' ) || summary_analysis['entities'] == nil || summary_analysis['entities'].size == 0
        Log.debug(format('Running entities analysis').yellow)
        summary_analysis['entities'] = analyze_body_entities['entities']
        #pp summary_analysis
        #exit
        save_summary = true
      end

      if !summary_analysis.has_key?( 'sentiment' ) 
        Log.debug(format('Running sentiment analysis').yellow)
        summary_analysis['sentiment'] = analyze_body_sentiment

        @score = summary_analysis['sentiment']['documentSentiment']['score']
        @magnitude = summary_analysis['sentiment']['documentSentiment']['magnitude']

        save_doc = true
        save_summary = true
      end

      if !summary_analysis.has_key?( 'syntax' ) || summary_analysis['syntax'] == nil
        Log.debug(format('Running syntax analysis').yellow)
        syntax = analyze_body_syntax( false )
        summary_analysis['syntax'] = syntax
        save_summary = true
      end

      if save_doc == true
        save( true )
        Misty::nap( 'Saving doc' )
      end

      if save_summary == true
        Log.debug(format('Saving entity analysis'))
        Dyn::save_article_entities_analysis( summary_analysis )
      end
    end

    def analyze_body_syntax( force=false )
      return false if !has_body?
      analyze( 'syntax', get_entire_body, force )
    end

    def analyze_body_entities( force=false )
      return false if !has_body?
      analyze( 'entities', get_entire_body )
    end

    def analyze_body_sentiment( force=false )
      return false if !has_body?
      analyze( 'sentiment', get_entire_body )
    end

    def emote
      get_body.each do |body_el|
        if body_el['body'].match( /mental state/ )
          Log.debug( 'Found mental state' )
        end
      end
    end

  end
end
