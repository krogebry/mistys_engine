
module Misty

  class DataStore
    def initialize
    end
  end

  class Dyn < DataStore

    OBJECT_TYPE_TOPIC = 'topic'
    OBJECT_TYPE_ARTICLE = 'article'
    OBJECT_TYPE_ARTICLE_LINE = 'article_line'

    OBJECT_TAG_TYPE_VOTE = 'vote'
    OBJECT_TAG_TYPE_EMOTION = 'emotion'
    OBJECT_TAG_TYPE_FAVORITE = 'favorite'

    def self.get_object_tags( object_type, object_id, force=false )
      object_key = format('%s-%s', object_type, object_id)
      cache_key = 'topics_dev_object_tags_%s' % object_key
      Cache.del_key( cache_key ) if force == true
      data = Cache.cached_json( cache_key ) do
        query = {
          index_name: 'object_key-index',
          table_name: format('misty_%s_object_tags', ENV['MISTY_ENV_NAME']),
          expression_attribute_values: { ':v1' => object_key }, 
          key_condition_expression: 'object_key = :v1'
        }
        DynamoClient.query( query ).data.to_h.to_json
      end

      if data['items'].size == 0
        { 
          'tags' => [],
          'object_id' => object_id,
          'object_key' => format('%s-%s', object_type, object_id),
          'object_type' => object_type
        }
      else
        data['items'].first
      end
    end

    def self.get_batch_object_tags( object_type, object_ids, force=false )
      object_key = format('%s-%s', object_type, Misty::Dyn::digest( object_ids.join() ))
      cache_key = format('topics_dev_object_tags_%s', object_key)
      Cache.del_key( cache_key ) if force == true

      data = Cache.cached_json( cache_key ) do
        table_name = format('misty_%s_object_tags', ENV['MISTY_ENV_NAME'])
        query = {
          request_items: {
            table_name => {
              keys: object_ids.map{|id| { 'object_id' => id }}
            }
          }
        }

        # pp query

        DynamoClient.batch_get_item( query ).data.to_h.to_json
      end
      data
    end

    def self.tag_object( object_type, object_id, user_id, tag_type, tag_value )
      #object_key = format('%s-%s', object_type, object_id)

      tag_object = get_object_tags( object_type, object_id, true )

      tag_object['tags'] ||= []
      tag_object['tags'].push({
        'user_id' => user_id,
        'tag_type' => tag_type,
        'tag_value' => tag_value,
        'created_ts' => Time.new.to_f
      })

      # pp tag_object

      DynamoClient.put_item({
        item: tag_object,
        table_name: format('misty_%s_object_tags', ENV['MISTY_ENV_NAME'])
      })

      cache_key = 'topics_dev_object_tags_%s' % tag_object['object_key']
      Cache.del_key( cache_key ) 
    end

    def self.digest( str )
      Digest::SHA1.hexdigest( str )
    end
    
    def self.save_article( article )
      DynamoClient.put_item({
        item: article,
        table_name: 'misty_dev_articles'
      })
    end

    def self.save_subject_importance_map( doc )
      DynamoClient.put_item({
        item: doc,
        table_name: 'misty_dev_subject_importance_map'
      })
    end

    def self.save_article_entities_analysis( doc )
      line_id = format('%s-%s', doc['article_id'], doc['digest'])
      [ 'sentiment', 'syntax', 'entities' ].each do |k|
        cache_key = format('misty_dev_aa_%s_%s', k, line_id)
        Log.debug(format('Saving: %s', cache_key))
        S3Client.put_object({
          key: format('analysis/dev/%s', cache_key),
          body: doc[k].to_json,
          bucket: 'mistysengine'
        })
        Misty::nap( 'Saving s3 object' )
      end

      get_article_analysis( doc['article_id'], doc['digest'], true )
    end

    def self.get_article_analysis( article_id, digest, force=false )
      return_data = {}
      line_id = format('%s-%s', article_id, digest)
      [ 'sentiment', 'syntax', 'entities' ].each do |k|
        cache_key = format('misty_dev_aa_%s_%s', k, line_id)
        # Log.debug(format('Del: %s (%s)', cache_key, force))
        Cache.del_key( cache_key ) if force == true

        data = Cache.cached_json( cache_key ) do
          begin
            object = ""
            S3Client.get_object({
              key: format('analysis/dev/%s', cache_key ),
              bucket: 'mistysengine'
            }) do |chunk|
              object << chunk
            end
            Misty::nap( 'Getting s3 object' )

          rescue Aws::S3::Errors::NoSuchKey => e
            # Log.debug(format('No key: %s', e).red)
            object = [].to_json

          end
          object
        end
        return_data[k] = data
      end
      return_data
    end

    def self.save_article_analysis( doc )
      DynamoClient.put_item({
        item: doc,
        table_name: 'misty_dev_article_analysis'
      })
    end

    def self.save_topic_occurance_map( doc )
      DynamoClient.put_item({
        item: doc,
        table_name: format('misty_%s_topic_occurance_map', ENV['MISTY_ENV_NAME'])
      })
    end

    def self.get_topic_occurance_map( topic_id, force=false )
      query = {
        index_name: 'topic_id-index',
        table_name: format('misty_%s_topic_occurance_map', ENV['MISTY_ENV_NAME']),
        expression_attribute_values: {
          ':v1' => topic_id
        }, 
        key_condition_expression: 'topic_id = :v1' 
      }
      cache_key = format('misty_%s_topic_occurance_map_%s', ENV['MISTY_ENV_NAME'], topic_id)
      Cache.del_key( cache_key ) if force == true
      data = Cache.cached_json( cache_key ) do
        DynamoClient.query( query ).data.to_h.to_json
      end
      data['items'].first
    end

    def self.get_subject_importance_map( topic_id, force=false )
      query = {
        index_name: 'topic_id-index',
        table_name: 'misty_dev_subject_importance_map',
        expression_attribute_values: {
          ':v1' => topic_id
        }, 
        key_condition_expression: 'topic_id = :v1' 
      }
      cache_key = format('misty_%s_subject_importance_map_%s', ENV['MISTY_ENV_NAME'], topic_id)
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

      cache_key = format('article_%s_%s', ENV['MISTY_ENV_NAME'], article_id)
      Cache.del_key( cache_key ) if force == true

      data = Cache.cached_json( cache_key ) do
        DynamoClient.query( query ).data.to_h.to_json
      end
      Misty::Article.new( data['items'].first )
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

