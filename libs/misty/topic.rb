require 'unidecoder'

module Misty

  class Topic
    @topic
    @articles
    @topic_id

    def initialize( topic_id )
      @topic_id = topic_id
      @topic = Dyn::get_topic_by_id( @topic_id )
    end

    def get_articles
      @articles = Dyn::get_articles_by_topic_id( @topic_id )
    end

    def summarize
      get_articles

      totals = {
        :mr => {},
        :score => 0.0,
        :magnitude => 0.0
      }

      article_summaries = {}

      @articles['items'].each do |article|
        article_totals = {
          :mr => {},
          :score => 0.0,
          :magnitude => 0.0
        }

        next if !article['article'].has_key?( 'body' )

        Log.debug(format('Processing: %s', article['article_id']))

        article['article']['body'].each do |body|
          digest = Digest::SHA1.hexdigest( body['body'] )
          analysis = Dyn::get_article_analysis( article['article_id'], digest )
          next if !analysis.has_key?( 'entities' ) || !analysis['entities'].has_key?( 'entities' )
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

        article_summaries[article['article_id']] = article_totals
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
      # pp @topic
      Dyn::save_topic( @topic )
      Log.debug('Sleeping on topic save')
      sleep rand(10)
    end

  end
end

