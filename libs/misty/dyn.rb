
module Misty

  class DataStore
    def initialize
    end
  end

  class Dyn < DataStore

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
      begin
        [ 'sentiment', 'syntax', 'entities' ].each do |k|
          #this_doc = {
            #k => doc[k],
            #'digest' => doc['digest'],
            #'article_id' => doc['article_id'],
            #'article_id_digest' => doc['article_id_digest']
          #}

          Log.debug(format('Saving: %s', k))

          S3Client.put_object({
            key: format('analysis/dev/%s_%s', k, doc['article_id_digest'] ),
            body: doc[k].to_json,
            bucket: 'mistysengine'
          })
        end

        Misty::nap('Saving article analysis')
        get_article_analysis( doc['article_id'], doc['digest'], true )
        #Misty::nap('Flushing article analysis cache')

      rescue Aws::DynamoDB::Errors::ValidationException => e
        Log.fatal(format('save failed: %s', e).red)
        exit

      end
    end

    def self.get_article_analysis( article_id, digest, force=false )
      return_data = {}
      line_id = format('%s-%s', article_id, digest)
      [ 'sentiment', 'syntax', 'entities' ].each do |k|
        #query = {
          #index_name: 'article_id_digest-index',
          #table_name: format('misty_dev_article_analysis_%s', k),
          #expression_attribute_values: {
            #':v1' => line_id
          #}, 
          #key_condition_expression: 'article_id_digest = :v1' 
        #}

        cache_key = format('misty_dev_aa_%s_%s', k, line_id)
        Cache.del_key( cache_key ) if force == true

        data = Cache.cached_json( cache_key ) do
          begin
            object = ""
            S3Client.get_object({
              key: format('analysis/dev/%s_%s', k, line_id ),
              bucket: 'mistysengine'
            }) do |chunk|
              object << chunk
            end

          rescue Aws::S3::Errors::NoSuchKey => e
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

