
def get_num_messages( queue_url )
  resp = SQSClient.get_queue_attributes({
    queue_url: queue_url,
    attribute_names: ["ApproximateNumberOfMessages"]
  })
  resp.attributes['ApproximateNumberOfMessages'].to_i
end

namespace :sqs do

  desc 'Process articles'
  task :article_scan do |t,args|
    queue_url = format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_article_scan', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME'])
    while true
      messages = SQSClient.receive_message( queue_url: queue_url )
      messages.messages.each do |message|
        body = JSON::parse message.body 
        Rake::Task['article:grab'].invoke body['topic_id'], body['url']
      	Rake::Task['article:grab'].reenable

        SQSClient.delete_message(
          queue_url: queue_url,
          receipt_handle: message.receipt_handle
        )
      end
      Misty::nap( 'Sleeping on queue article_scan' )

      num_in_queue = get_num_messages( queue_url )
      if num_in_queue == 0
        Log.info('No more work left')
        exit
      end

    end
  end

  desc 'Process occurance maps'
  task :create_om do |t,args|
    queue_url = format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_create_om', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME'])
    while true
      messages = SQSClient.receive_message( queue_url: queue_url )
      messages.messages.each do |message|
        body = JSON::parse message.body 
        topic = Misty::Dyn.get_topic_by_id( body['topic_id'] )
        topic.make_occurance_map
        SQSClient.delete_message(
          queue_url: queue_url,
          receipt_handle: message.receipt_handle
        )
      end

      Misty::nap( 'Sleeping on queue create_om' )

      num_in_queue = get_num_messages( queue_url )
      if num_in_queue == 0
        Log.info('No more work left')
        exit
      end

    end
  end

  desc 'Process create subject importance mappings'
  task :create_sim do |t,args|
    queue_url = format('https://sqs.us-east-1.amazonaws.com/%s/misty_%s_create_sim', ENV['AWS_ACCOUNT_ID'], ENV['MISTY_ENV_NAME'])

    while true
      messages = SQSClient.receive_message( queue_url: queue_url )
      messages.messages.each do |message|
        body = JSON::parse message.body 
        topic = Misty::Dyn.get_topic_by_id( body['topic_id'] )
        topic.create_subject_importance_map

        SQSClient.delete_message(
          queue_url: queue_url,
          receipt_handle: message.receipt_handle
        )
      end
      Misty::nap( 'Sleeping on queue create_sim' )

      num_in_queue = get_num_messages( queue_url )
      if num_in_queue == 0
        Log.info('No more work left')
        exit
      end

    end
  end
end

