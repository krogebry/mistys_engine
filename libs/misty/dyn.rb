
module Misty

  class DataStore
    def initialize
    end
  end

  class Dyn < DataStore
    
    def self.save_article( article )
      DynamoClient.put_item({
        item: article,
        table_name: 'misty_dev_articles'
      })
    end

    def self.save_article_analysis( doc )
      DynamoClient.put_item({
        item: doc,
        table_name: 'misty_dev_article_analysis'
      })
    end

    def self.get_article_analysis( article_id, digest, force=false )
      line_id = format('%s-%s', article_id, digest)
      query = {
        index_name: 'article_id_digest-index',
        table_name: 'misty_dev_article_analysis',
        expression_attribute_values: {
          ':v1' => line_id
        }, 
        key_condition_expression: 'article_id_digest = :v1' 
      }
      cache_key = format('misty_dev_article_analysis_%s', line_id)

      Cache.del_key( cache_key ) if force == true

      data = Cache.cached_json( cache_key ) do
        DynamoClient.query( query ).data.to_h.to_json
      end
      data['items'].first
    end

    def self.save_topic( topic )
      DynamoClient.put_item({
        item: topic,
        table_name: 'misty_dev_topics'
      })
    end

    def self.get_topics( force=false )
      query = {
        table_name: format('misty_%s_topics', ENV['MISTY_ENV_NAME'])
      }
      cache_key = format('topics_%s', ENV['MISTY_ENV_NAME'])
      Cache.del_key( cache_key ) if force == true
      data = Cache.cached_json( cache_key ) do
        DynamoClient.scan( query ).data.to_h.to_json
      end

      topics = []
      data['items'].each do |item|
        topics.push(Misty::Topic.new( item ))
      end
      topics
    end

    def self.get_topic_by_id( topic_id, force=false )
      query = {
        index_name: 'topic_id-index',
        table_name: 'misty_dev_topics',
        expression_attribute_values: {
          ':v1' => topic_id
        }, 
        key_condition_expression: 'topic_id = :v1'
      }
      cache_key = 'topics_dev_%s' % topic_id
      Cache.del_key( cache_key ) if force == true
      data = Cache.cached_json( cache_key ) do
        DynamoClient.query( query ).data.to_h.to_json
      end
      Misty::Topic.new( data['items'].first )
    end

    def self.get_article_by_id( article_id, force=false )
      query = {
        table_name: 'misty_dev_articles',
        expression_attribute_values: {
          ':v1' => article_id
        }, 
        key_condition_expression: 'article_id = :v1'
      }

      cache_key = 'article_dev_%s' % article_id
      Cache.del_key( cache_key ) if force == true

      data = Cache.cached_json( cache_key ) do
        DynamoClient.query( query ).data.to_h.to_json
      end
      data['items'].first
    end

    def self.get_articles_by_topic_id( topic_id, force=false )
      query = {
        limit: 200,
        index_name: 'topic_id-index',
        table_name: 'misty_dev_articles',
        expression_attribute_values: {
          ':v1' => topic_id
        }, 
        key_condition_expression: 'topic_id = :v1'
      }

      cache_key = 'articles_dev_%s' % topic_id
      Cache.del_key( cache_key ) if force == true

      articles = []
      data = Cache.cached_json( cache_key ) do
        ptr = DynamoClient.query( query )
        data = { 'items' => ptr.data.items }
        has_more_data = (ptr['last_evaluated_key'] == nil ? false : true)
        while has_more_data 
          query['exclusive_start_key'] = ptr['last_evaluated_key']
          ptr = DynamoClient.query( query )
          ptr.data['items'].each do |row|
            data['items'].push row
          end
          has_more_data = (ptr['last_evaluated_key'] == nil ? false : true)
        end
        data.to_json
      end

      data['items'].each do |item|
        articles.push(Misty::Article.new( item ))
      end
      articles
    end

  end
end

