
get "/healthz" do
  { :success => true }.to_json
end

get "/flush_cache" do
  DevOps::Cache::flush
end

get "/" do
  query = {
    table_name: 'misty_dev_topics'
  }
  cache_key = 'topics_%' % ENV['MISTY_ENV_NAME']
  topics = Cache.cached_json( cache_key ) do
    DynamoClient.scan( query ).data.to_h.to_json
  end

  erb :index, :locals => { :topics => topics['items'] }
end

get "/topic/create" do
  erb "topic/create".to_sym
end

get "/topic/add_source" do
  erb "topic/add_source".to_sym, :locals => { :topic_id => params['topic_id'] }
end

post "/topic/create" do
  DynamoClient.put_item({
    item: {
      topic_id: Digest::SHA1.hexdigest( params['topic_name'] ),
      scrape_url: params['scrape_url'],
      topic_name: params['topic_name']
    },
    table_name: 'misty_dev_topics'
  })
	Cache.del_key 'topics_%s' % ENV['MISTY_ENV_NAME']
  redirect "/"
end

post "/topic/add_source" do
	message = {
		:url => params['url'],
		:topic_id => params['topic_id']
	}

	begin
		SQSClient.send_message(
			queue_url: format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME']),
			message_body: message.to_json
		)

	rescue => e
		Log.fatal('Unable to queue message: %s', e)

	end
	redirect '/'
end

get "/topic/:topic_id" do
  topic = Misty::Dyn::get_topic_by_id( params[:topic_id] )
  articles = topic.get_articles
  pp topic.get_summary
  erb :topic, :locals => { :topic => topic, :articles => articles }
end

get "/topic/:topic_id/refresh" do
  topic = Misty::Dyn::get_topic_by_id( params[:topic_id], true )
	articles = Misty::Dyn::get_articles_by_topic_id( params[:topic_id], true )
  pp articles
  { :success => true }.to_json
end

get "/article/:article_id" do
  article = Misty::Dyn::get_article_by_id( params[:article_id] )
  erb :article, :locals => { :article => article }
end

get "/article/:article_id/refresh" do
  article = Misty::Dyn::get_article_by_id( params[:article_id], true )
  { :success => true }.to_json
end
