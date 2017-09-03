
module Misty

  def self.nap( banner )
    timer = rand( 0.900 ) + rand( 0.800 )
    Log.debug(format('Sleeping for %.4f for %s', timer, banner).yellow)
    sleep timer
  end

end

require format('%s/misty/dyn.rb', LIB_DIR)
require format('%s/misty/topic.rb', LIB_DIR)
require format('%s/misty/sources.rb', LIB_DIR)
require format('%s/misty/article.rb', LIB_DIR)
