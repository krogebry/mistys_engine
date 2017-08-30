
get "/healthz" do
  { :success => true }.to_json
end

get "/flush_cache" do
  DevOps::Cache::flush
end

get "/" do
  query = {
    table_name: 'misty_dev_topics'
    #expression_attribute_values: {
      #':v1' => {
        #s: '*'
      #} 
    #}, 
    #key_condition_expression: 'topic_name = :v1'
  }

  cache_key = 'topics_dev'
  topics = Cache.cached_json( cache_key ) do
    DynamoClient.scan( query ).data.to_h.to_json
  end

  erb :index, :locals => { :topics => topics['items'] }
end

def get_topic_by_id( topic_id )
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

def get_article_by_id( article_id )
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

get "/topic/:topic_id" do
  query = {
    index_name: 'topic_id-index',
    table_name: 'misty_dev_articles',
    expression_attribute_values: {
      ':v1' => params[:topic_id]
    }, 
    key_condition_expression: 'topic_id = :v1'
  }

  cache_key = 'articles_dev_%s' % params[:topic_id]
  articles = Cache.cached_json( cache_key ) do
    DynamoClient.query( query ).data.to_h.to_json
  end

  topic = get_topic_by_id( params[:topic_id] )

  erb :topic, :locals => { :topic => topic, :articles => articles['items'] }
end

get "/article/:article_id" do
  article = get_article_by_id( params[:article_id] )
  erb :article, :locals => { :article => article }
end


