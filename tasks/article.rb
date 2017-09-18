namespace :article do
  desc 'Analyze'
  task :lang, :article_key do |t,args|
    article = Misty::Dyn::get_article_by_id( args[:article_key] )
    article.analyze_language( false )
  end

  desc 'Grab by id'
  task :scrape, :article_key do |t,args|
    article = Misty::Dyn::get_article_by_id( args[:article_key] )
    #pp article
    if article.process_page( article.url, article.article_id )
      article.analyze_language( true )
      article.save( true )
    end
  end

  desc "Map xpaths"
  task :map_xpaths do |t,args|
    mr = {}
    Misty::SOURCES_MAP.each do |hostname, xpaths|
      next if hostname == 'template'
      xpaths.each do |k,v|
        mr[k] ||= {}
        mr[k][v] ||= 0
        mr[k][v] += 1
      end
    end
  end

  desc "Grab an article"
  task :grab, :key, :url, :long do |t,args|
    long_timer = true if args[:long] != nil

    article = Misty::Article::get_by_url( args[:url] )
    if article.process_page( args[:url], args[:key] )
      article.analyze_language( true )
      article.save( false )
      # Misty::nap( 'Article save', long_timer )
    end
  end
end
