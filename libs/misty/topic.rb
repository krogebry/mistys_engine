require 'unidecoder'

module Misty

  class Topic
    @data
    @topic_id
    @topic_name

    @created_ts

    @scrape_url

    def self.create( topic_name, topic_scrape_url )
  		DynamoClient.put_item({
    		item: {
      		topic_id: Digest::SHA1.hexdigest( topic_name ),
          created_ts: Time.new.to_f,
      		scrape_url: topic_scrape_url,
      		topic_name: topic_name
    		},
    		table_name: format( 'misty_%s_topics', ENV['MISTY_ENV_NAME'] )
  		})
  		Cache.del_key(format('topics_%s', ENV['MISTY_ENV_NAME'] ))
		end

    attr_accessor :topic_id, :topic_name, :scrape_url, :created_ts
    def initialize( data )
      @data = data
      @topic_id = @data['topic_id']
      @topic_name = @data['topic_name']

      @created_ts = @data['created_ts'].to_f if @data.has_key? 'created_ts'
      @scrape_url = @data['scrape_url'] if @data.has_key? 'scrape_url'
    end

    def get_articles( force=false )
      Dyn::get_articles_by_topic_id( @topic_id, force )
    end

    def get_occurance_map( force=false )
      Dyn::get_topic_occrurance_map( @topic_id, force )
    end

    def update_ts
      if @created_ts == nil
        @data['created_ts'] = Time.new.to_f 
        save
      end
    end

    def has_summary?
      @data.has_key?( 'summary' )
    end

    def get_summary
      @data['summary']
    end

    def has_summary_for_article?( article_id )
      get_summary().has_key?( article_id )
    end

    def get_summary_for_article( article_id )
      get_summary()[article_id]
    end

    def summarize
      totals = {
        :mr => {},
        :score => 0.0,
        :magnitude => 0.0
      }

      article_summaries = {}

      get_articles.each do |article|
        article_totals = {
          :mr => {},
          :score => 0.0,
          :magnitude => 0.0
        }

        next if !article.has_body?
        Log.debug(format('Processing: %s', article.article_id))

        article.get_body.each do |body|
          digest = Digest::SHA1.hexdigest( body['body'] )
          analysis = Dyn::get_article_analysis( article.article_id, digest )

          next if analysis == nil || !analysis.has_key?( 'entities' ) || !analysis['entities'].has_key?( 'entities' )

          analysis['entities']['entities'].each do |e|
            mention_type = e['mentions'].first['type']
            next if mention_type != 'PROPER'
            article_totals[:mr][e['type']] ||= {}
            article_totals[:mr][e['type']][e['name']] ||= { :cnt => 0, :pct => 0.0 }
            article_totals[:mr][e['type']][e['name']][:cnt] += 1
          end

          if body.has_key?( 'sentiment' )
            article_totals[:score] += body['sentiment']['score'].to_f
            article_totals[:magnitude] += body['sentiment']['magnitude'].to_f
          end
        end

        article_summaries[article.article_id] = article_totals
      end

      map = {}

      article_summaries.each do |article_id, article_map|
        article_map[:mr].each do |context, info|
          map[context] ||= {}
          info.each do |name, info|
            map[context][name] ||= 0
            map[context][name] += info[:cnt]
          end
        end
      end

      article_summaries.each do |article_id, article_map|
        article_map[:mr].each do |context, info|
          map[context] ||= {}
          info.each do |name, info|
            pct = (info[:cnt].to_f / map[context][name].to_f) * 100
            info[:pct] = pct
          end
        end
      end

      @data['summary'] = article_summaries
    end

    def save
      Dyn::save_topic( @data )
      Misty::nap( 'topic save' )
    end

   	def make_occurance_map
      max_diff_thresh = 5

    	articles = get_articles.select{|a| a.has_body? }
    	Log.debug(format('Found %i articles', articles.size))

    	occurance_map = {
      	'map' => {},
      	'topic_id' => @topic_id
    	}

    	skip_lines = [
        'None',
      	'© 2017 KSDK-TV',
        'Story Continued Below',
      	'Thank you for your support.',
        'Keep up with this story and more by subscribing now',
      	'We rely on advertising to help fund our award-winning journalism.',
        'Letters to the editor on topics of general interest are welcomed and encouraged.',
      	'We urge you to turn off your ad blocker for The Telegraph website so that you can continue to access our quality content in the future.'
    	]

    	articles.each do |article|
      	article.get_body.each do |body|
        	next if skip_lines.include?( body['body'] )
        	occurance_map['map'][body['digest']] ||= { 'body' => body['body'], 'refs' => [] }
        	obj = {
          	'line_id' => body['line_id'],
          	'article_id' => article.article_id
        	}
        	occurance_map['map'][body['digest']]['refs'].push( obj )
      	end
    	end

    	occurance_map['map'].select!{|d,i| i['refs'].size >= max_diff_thresh } 
    	Misty::Dyn::save_topic_occurance_map( occurance_map )
    	Misty::Dyn::get_topic_occurance_map( @topic_id, true ) 
		end

    def create_subject_importance_map
    	quote_map = {}
    	salience_map = {}

    	get_articles.each do |article|
      	next if !article.has_body?

      	sum = article.get_summary_analysis( false )
      	if sum == nil || sum['entities'] == nil
        	Log.debug(format('Article is missing summary: %s', article.article_id))
					next
      	end

      	sorted_by_salience = sum['entities'].map{|e| e.merge({ 'salience' => e['salience'].to_f })}.sort{|a,b| b['salience'] <=> a['salience'] }

      	sorted_by_salience[0..5].each do |s|
        	salience_map[s['name']] ||= { :cnt => 0.0, :salience => 0.0, :num_mentions => 0.0, :mentions => [] }
        	salience_map[s['name']][:cnt] += 1
        	salience_map[s['name']][:salience] += s['salience']
        	salience_map[s['name']][:mentions] << s['mentions']
        	salience_map[s['name']][:mentions].flatten!
      	end
    	end

    	subject_importance_map = {}
    	salience_map.sort_by{|k,v| v[:salience] }.reverse[0..10].to_h.each do |name, info|
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
    	Log.debug('Saving subject importance map')
    	Misty::Dyn::save_subject_importance_map({
      	'map' => subject_importance_map,
      	'topic_id' => @topic_id
    	})
    end

  end
end

