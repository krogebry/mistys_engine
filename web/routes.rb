
get "/healthz" do
  { :success => true }.to_json
end

get "/flush_cache" do
  DevOps::Cache::flush
end

get "/" do
  query = { table_name: 'misty_dev_topics' }
  cache_key = 'topics_%' % ENV['MISTY_ENV_NAME']
  topics = Cache.cached_json( cache_key ) do
    DynamoClient.scan( query ).data.to_h.to_json
  end

  erb :index, :locals => { :topics => topics['items'] }
end

get "/topics/refresh" do
  cache_key = 'topics_%' % ENV['MISTY_ENV_NAME']
  Cache.del_key( cache_key )
  redirect "/"
end

get "/topic/create" do
  erb "topic/create".to_sym
end

get "/topic/add_source" do
  erb "topic/add_source".to_sym, :locals => { :topic_id => params['topic_id'] }
end

post "/topic/create" do
  Misty::Topic::create( params['topic_name'], params['scrape_url'] )
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
  subject_importance_map = Misty::Dyn::get_subject_importance_map( topic.topic_id )
  if subject_importance_map != nil
    subject_importance_map['map'] = subject_importance_map['map'].sort_by{|k,v| v['salience'].to_f }.reverse.to_h
  end
  erb :topic, :locals => { :topic => topic, :articles => articles, :subject_importance_map => subject_importance_map }
end

get "/topic/:topic_id/refresh" do
  topic = Misty::Dyn::get_topic_by_id( params[:topic_id], true )
	articles = Misty::Dyn::get_articles_by_topic_id( params[:topic_id], true )
  subject_importance_map = Misty::Dyn::get_subject_importance_map( topic.topic_id, true )
  { :success => true }.to_json
end

get "/article/:article_id" do
  article = Misty::Dyn::get_article_by_id( params[:article_id] )
  summary_analysis = article.get_summary_analysis()
  pp article.get_body()
  erb :article, :locals => { :article => article, :summary_analysis => summary_analysis }
end

post "/article/:article_id/add_bias" do
  article = Misty::Dyn::get_article_by_id( params[:article_id] )
  pp params
  Log.debug("Adding bias")
  #summary_analysis = article.get_summary_analysis()
  #erb :article, :locals => { :article => article, :summary_analysis => summary_analysis }
  article.add_bias( params[:digest], params[:bias] )
  { :success => true }.to_json
end

get "/article/:article_id/refresh" do
  article = Misty::Dyn::get_article_by_id( params[:article_id], true )
  { :success => true }.to_json
end

get "/article/:article_id/line/:digest" do
  analysis = Misty::Dyn::get_article_analysis( params[:article_id], params[:digest] )
  erb "article/analysis".to_sym, :locals => { :analysis => analysis }
end

get "/fact_check" do
  erb "fact_check".to_sym
end

post "/fact_check" do
  #pp params
  #topic = Misty::Dyn::get_topic_by_id( '3f451fdb2a31a5a7269f6114ab41fa658fd152fd' )
  results = []
  Misty::Dyn::get_topics.each do |topic|
    results << topic.get_articles.select{|a| a.has_body? && a.get_entire_body.match( params['search'] )}
  end
  results.flatten!
  erb "fact_check_results".to_sym, { :locals => {  :results => results }}
end

