require 'unidecoder'

module Misty

  class Topic
    @topic
    @topic_id
    @topic_name

    @scrape_url

    def self.create( topic_name, topic_scrape_url )
  		DynamoClient.put_item({
    		item: {
      		topic_id: Digest::SHA1.hexdigest( topic_name ),
      		scrape_url: topic_scrape_url,
      		topic_name: topic_name
    		},
    		table_name: format( 'misty_%s_topics', ENV['MISTY_ENV_NAME'] )
  		})
  		Cache.del_key(format('topics_%s', ENV['MISTY_ENV_NAME'] ))
		end

    attr_accessor :topic_id, :topic_name, :scrape_url
    def initialize( data )
      @topic = data
      @topic_id = data['topic_id']
      @topic_name = data['topic_name']

      @scrape_url = data['scrape_url'] if data.has_key?( 'scrape_url' )
    end

    def get_articles( force=false )
      Dyn::get_articles_by_topic_id( @topic_id, force )
    end

    def has_summary?
      @topic.has_key?( 'summary' )
    end

    def get_summary
      @topic['summary']
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

      @topic['summary'] = article_summaries
    end

    def save
      Dyn::save_topic( @topic )
      Misty::nap( 'topic save' )
    end

  end
end

