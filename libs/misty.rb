
module Misty

  def self.nap( banner, long=false )
    timer = rand( 0.900 ) + rand( 0.950 )
    timer += rand( 10 ) if long == true
    Log.debug(format('Sleeping %.4f for %s', timer, banner).yellow)
    sleep timer
  end

end

require format('%s/misty/dyn.rb', LIB_DIR)
require format('%s/misty/tags.rb', LIB_DIR)
require format('%s/misty/topic.rb', LIB_DIR)
require format('%s/misty/sources.rb', LIB_DIR)
require format('%s/misty/article.rb', LIB_DIR)
require format('%s/misty/bias_engine.rb', LIB_DIR)
