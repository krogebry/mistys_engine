
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

    def self.get_article_analysis( article_id, digest )
      line_id = format('%s-%s', article_id, digest)
      query = {
        index_name: 'article_id_digest-index',
        table_name: 'misty_dev_article_analysis',
        expression_attribute_values: {
          ':v1' => line_id
        }, 
        key_condition_expression: 'article_id_digest = :v1' 
      }
      # pp query
      cache_key = format('misty_dev_article_analysis_%s', line_id)
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

    def self.get_topic_by_id( topic_id )
      query = {
        index_name: 'topic_id-index',
        table_name: 'misty_dev_topics',
        expression_attribute_values: {
          ':v1' => topic_id
        }, 
        key_condition_expression: 'topic_id = :v1'
      }
      cache_key = 'topics_dev_%s' % topic_id
      data = Cache.cached_json( cache_key ) do
        DynamoClient.query( query ).data.to_h.to_json
      end
      data['items'].first
    end

    def self.get_article_by_id( article_id )
      query = {
        #index_name: 'article_id-index',
        table_name: 'misty_dev_articles',
        expression_attribute_values: {
          ':v1' => article_id
        }, 
        key_condition_expression: 'article_id = :v1'
      }
      cache_key = 'article_dev_%s' % article_id
      data = Cache.cached_json( cache_key ) do
        DynamoClient.query( query ).data.to_h.to_json
      end
      data['items'].first
    end

    def self.get_articles_by_topic_id( topic_id )
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

      Cache.cached_json( cache_key ) do
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

    end

  end
end

