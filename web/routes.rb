
# @oauth = Koala::Facebook::OAuth.new(app_id, app_secret, callback_url)
# @oauth.get_app_access_token

APP_ID='171439776757489'
APP_SECRET='326a00e8e06c2fa609f5b66b59072d04'

get "/healthz" do
  { :success => true }.to_json
end

get "/flush_cache" do
  DevOps::Cache::flush
end

get "/fb_oauth_callback" do
  Log.debug(format('Code: %s', params[:code]).yellow)
  session['access_token'] = session['oauth'].get_access_token(params[:code])

  graph = Koala::Facebook::API.new( session['access_token'] )
  session['user'] = graph.get_object( 'me' )

  redirect '/'
end

before do
  if session['access_token']
    Log.debug('Logged in'.green)
    Log.debug(format('AccessToken: %s', session['access_token']).blue)

  else
    Log.debug('Not logged in'.red )

  end
end

get '/' do
  topics = Misty::Dyn::get_topics( false )
  erb :index, :locals => { :topics => topics }
end

get '/login' do
	session['oauth'] = Koala::Facebook::OAuth.new(APP_ID, APP_SECRET, "#{request.base_url}/fb_oauth_callback")
	redirect session['oauth'].url_for_oauth_code()
end

get '/logout' do
	session['user'] = nil
	session['oauth'] = nil
	session['access_token'] = nil
	redirect '/'
end

get "/topics/refresh" do
  topics = Misty::Dyn::get_topics( true )
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
  tag_objects = article.get_line_tags
  erb :article, :locals => { :tag_objects => tag_objects, :article => article, :summary_analysis => summary_analysis }
end

post "/article/:article_id/tag" do
  article = Misty::Dyn::get_article_by_id( params[:article_id] )
  Log.debug("Adding tag to article")
  article.add_tag( params[:tag] )
  { :success => true }.to_json
end

post "/article/:article_id/line/:digest/tag" do
  r = { :success => false }
  if session.has_key?( 'user' )
    Log.debug(format('Tagging article line for user: %s', session['user']['name']))
    begin
      article = Misty::Dyn::get_article_by_id( params[:article_id] )
      article.tag_line( params[:digest], params[:tag_type], params[:tag_value], session['user'] )
      r[:success] = true

    rescue => e
      Log.fatal(format('Unable to tag article line: %s', e ))
      r[:reason] = e

    end
  end
  r.to_json
  { :success => true }.to_json
end

post "/article/:article_id/line/:digest/vote" do
  r = { :success => false }
  if session.has_key?( 'user' )
    Log.debug(format('Voting article line for user: %s', session['user']['name']))
    begin
      article = Misty::Dyn::get_article_by_id( params[:article_id] )
      article.vote_line( params[:digest], params[:direction], session['user'] )
      r[:success] = true
    rescue => e
      Log.fatal(format('Unable to upvote: %s', e ))
      r[:reason] = e
    end
  end
  r.to_json
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

