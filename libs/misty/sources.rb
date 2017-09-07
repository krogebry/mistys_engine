module Misty

  BROKEN_SITES = [
    'www.forbes.com'
  ]

  DRUPAL_7 = {
    'body' => '//div[@itemprop=articleBody]/p',
    'title' => '//h1[@itemprop=headline]',
    'authors' => '//span[@itemprop=name]',
    'update_time' => '//time'
  }

  WORDPRESS = {
    'body' => '//div[@class=entry-content]/div/p',
    'title' => '//h1[@class=entry-title]',
    'authors' => '//span[@class=entry-title]/a',
    'update_time' => '//span[@class=updated-time]'
  }

  WORDPRESS_481 = { ## boingboing
    'body' => '//div[@id=story]/p',
    'title' => '//div[@id=headline]/h1',
    # 'authors' => '//span[@class=entry-title]/a',
    # 'update_time' => '//span[@class=updated-time]'
  }

  SOURCES_MAP = {
    'template' => {
      'body' => '',
      'title' => '',
      'authors' => ''
    },

    'jacksonville.com' => {
      'body' => '//div[@class=field-article-body]/div/p',
      'title' => '//h1[@class*=story-title]',
      'authors' => '//div[@class=field-authors]/a',
      'published_at' => '//span[@class=story-date-data]'
    },

    'weather.com' => {
      'body' => '//div[@class*=field-name-body]/div/div/p',
      'title' => '//div[@class=pane-content]/h1',
      'published_time' => '//span[@class=date-display-single]'
    },

    # 'template' => {
      # 'body' => '//div[@class=story]/p',
      # 'title' => '//h1[@class=posttitle]',
      # 'published_time' => '//time[@class=entry-date]'
    # },

    'www.dhakatribune.com' => {
      'body' => '//div[@class=text]/p',
      'title' => '//h1[@class=post_title]',
      'authors' => '//item[@itemprop=name]'
    },

    'www.pakistantoday.com.pk' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//h1[@class=entry-title]',
      'updated_time' => '//time[@class=entry-date]'
    },

    'm.dailykos.com' => {
      'body' => '//div[@class*=intro-text]/noscript/p',
      'title' => '//div[@class=title]',
      'authors' => '//span[@class=author_name]',
      'published_time' => '//time[@class=dt-updated]'
    },

    'www.politico.com' => {
      'body' => '//div[@class*=story-text]/p',
      'title' => '//span[@itemprop=headline]',
      'authors' => '//a[@rel=author]',
      'published_time' => '//time[@itemprop=datePublished]'
    },

    'wjla.com' => {
      'body' => '//div[@class=sd-news-story-text]/p',
      'title' => '//div[@class=component-story-title-v1]/h1',
      'authors' => '//p[@class=sd-news-author]'
    },

    'us.blastingnews.com' => {
      'body' => '//div[@class*=article-body]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=name]',
      'updated_time' => '//time[@class*=time-modified]',
      'published_time' => '//time[@class*=time-published]'
    },

    'www.insideedition.com' => {
      'body' => '//div[@class*=article-txt]/p',
      'title' => '//h1[@id=main-headline]',
      # 'authors' => '', self published?
      'published_time' => '//time'
    },

    'www.bayoubuzz.com' => {
      'body' => '//div[@class=itemFullText]/p',
      'title' => '//h2[@class=itemTitle]',
      'authors' => '//span[@class=itemAuthor]/a',
      'updated_time' => '//time[@class=dt-updated]'
    },

    'www.foxnews.com' => {
      'body' => '//div[@class=article-body]/p',
      'title' => '//header[@class=article-header]/h1',
      'published_time' => '//time[@class=date]'
    },

    'www.politicususa.com' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//h1[@itemprop=name]'
    },

    'www.dailymail.co.uk' => {
      'body' => '//div[@itemprop=articleBody]/p',
      'title' => '//div[@id=js-article-text]/h1',
      'authors' => '//p[@class*=byline-plain]/a'
    },

    'nypost.com' => {
      'body' => '//div[@class*=entry-content]/p',
      'title' => '//div[@class=article-header]/h1/a',
      'authors' => '//div[@id=author-byline]/p/a'
    },

    'heavy.com' => {
      'body' => '//section[@class*=entry-content]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=author]/a',
      'published_time' => '//time[@class*=entry-date]'
    },

    'people.com' => {
      'body' => '//div[@class=article-body__inner]/p',
      'title' => '//h1[@class=article-header__title]',
      'authors' => '//a[@class*=author]'
    },

    'www.deathandtaxesmag.com' => {
      'body' => '//div[@itemprop=articleBody]/p',
      'title' => '//h1[@itemprop=name]'
      # 'authors' => '', not well formatted
      #'update_time' => '//meta[@property="article:modified_time"]',
      #'publish_time' => '//meta[@property="article:published_time"]'
    },

    'dfw.cbslocal.com' => {
      'body' => '//div[@class=story]/p',
      'title' => '//h1[@class=posttitle]',
      'update_time' => '//time[@class=entry-date]'
    },

    'metro.co.uk' => {
      'body' => '//div[@class=article-body]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//a[@class*=author]',
      'update_time' => '//span[@itemprop=datePublished]'
    },

    'www.cbsnews.com' => {
      'body' => '//div[@class=entry]/div/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@class=author]',
      'update_time' => '//span[@class=time]'
    },

    'www.rawstory.com' => {
      'body' => '//div[@class=blog-content]/p',
      'title' => '//h1[@class=blog-title]',
      'authors' => '//a[@ref=author]'
      # 'update_time' => '' ## garbage
    },

    'www.independent.co.uk' => {
      'body' => '//div[@itemprop=articleBody]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=name]/a',
      'update_time' => '//time'
    },

    'www.huffingtonpost.com' => {
      'body' => '//div[@class*=content-list-component]/p',
      'title' => '//h1[@class=headline__title]',
      'authors' => '//span[@class*=author-card__details__name]',
      'update_time' => '//span[@class=timestamp__date--published]'
    },

    'www.theguardian.com' => {
      'body' => '//div[@itemprop=articleBody]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=name]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'finance.yahoo.com' => {
      'body' => '//article[@itemprop=articleBody]/div/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//a[@itemprop=name]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'abcnews.go.com' => {
      'body' => 'div[@class=article-copy]/p',
      'title' => '//header[@class=article-header]/h1',
      #'authors' => '', ## junk spans
      'update_time' => '//span[@class=timestamp]'
    },

    'www.outsidethebeltway.com' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//h1[@class=entry-title]',
      'authors' => '//span[@class="author vcard"]/a' 
      #'update_time' => ''  ## garbage
    },

    'blog.gainesvillecoins.com' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//h1[@class=entry-title]',
      'authors' => '//p[@class=authordate]/a'
      # 'update_time' => '' ## needs work, might be possible
    },

    'www.latimes.com' => {
      'disabled' => true, ## fuck this site.
      #'body' => '//div[class=lb-card-body]/div/p',
      #'body' => '//div[@class*=lb-widget-text]/p',
      'title' => '//h2[@itemprop=headline]',
      'authors' => '//a[@itemprop=author]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'www.businessinsider.com' => {
      'body' => '//div[@class*=post-content]/p',
      'title' => '//div[@class=sl-layout-post]/h1',
      'authors' => '//li[@class=single-author]/a',
      'update_time' => '//span[@data-bi-format=date]'
    },

    'www.npr.org' => {
      'body' => '//div[@id=storytext]/p',
      'title' => '//div[@class=storytitle]/h1',
      'authors' => '//div[@class=byline-container--block]/div',
      'update_time' => '//div[@class=dateblock]/time'
    },

    'www.chicagotribune.com' => {
      'body' => '//div[@itemprop=articleBody]/div/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=author]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'www.scmagazine.com' => {
      'body' => '//div[@class=article-body]/div',
      'title' => '//article/h1[@class=title]',
      # 'authors' => '',  ## needs processing work
      'update_time' => '//article/time'
    },

    'www.mediaite.com' => {
      'body' => '//div[@id=post-body]/p',
      'title' => '//div[@id=post-heading]/h3',
      'authors' => '//div[@id=post-heading]/div[@class=dateline]/a'
      ## 'update_time' => '' ## garbage content for datetime
    },

    'www.cnbc.com' => { ## research HUD items as li's
      'body' => '//div[@itemprop=articleBody]/p',
      'title' => '//h1[@class=title]',
      'authors' => '//div[@itemprop=author]/a',
      'update_time' => '//time[@itemprop=dateUpdated]'  
    },

    'www.eenews.net' => {
      'body' => '//section[@class=content]/p',
      'title' => '//h1[@class=headline]',
      'authors' => '//p[@class=authors]/a',
      'update_time' => '//section[@class=byline]/time'
    },

    'talkingpointsmemo.com' => {
      'body' => '//div[@id=feature-content]/p',
      'title' => '//div[@class*=FeatureTitle]/h1',
      'authors' => '//a[@class*=author]'
      # 'update_time' => '' ## garbage spans for date/time
    },

    'www.washingtonexaminer.com' => {
      'body' => '//section[@class=article-body]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//a[@itemprop=author]/span[@itemprop=name]',
      'update_time' => '//time[@itemprop=datePublished]'
    },

    'www.nydailynews.com' => {
      'body' => '//article[@itemprop=articleBody]/p',
      'title' => '//h1[@id=ra-headline]',
      'authors' => '//div[@itemprop=author]/a[@itemprop=name]',
      'subtitle' => '//h2[@itemprop=description]',
      'update_time' => '//div[@itemprop=datePublished]'
    },

    'thehill.com' => {
      'body' => '//div[@class*=field-item]/p',
      'title' => '//h1[@class=title]',
      'authors' => '//span[@class=submitted-by]/a',
      'update_time' => '//span[@class=submitted-date]'
    },

    'www.cnn.com' => {
      'body' => '//div[@class=zn-body__paragraph]',
      'title' => '//h1[@class=pg-headline]',
      'authors' => '//span[@class=metadata__byline__author]/a',
      'update_time' => '//p[@class=update-time]'
    },
    'www.theroot.com' => {
      'body' => '//div[@class*=post-content]/p',
      'title' => '//h1[@class*=headline]',
      'authors' => '//div[@class*=meta__byline]/a',
      'update_time' => '//time[@class*=meta__time]'
    },
    'www.breitbart.com' => {
      'body' => '//div[@class=entry-content]/p',
      'title' => '//header/h1',
      'authors' => '//span[@class=by-author]/a',
      'update_time' => '//span[@class=bydate]'
    },
    'www.washingtonpost.com' => {
      'body' => '//article[@itemprop=articleBody]/p',
      'title' => '//h1[@itemprop=headline]',
      'authors' => '//span[@itemprop=author]/a/span[@itemprop=name]',
      'subtitle' => '//h2[@class=headline__subtitle]'
    }
  }

end
