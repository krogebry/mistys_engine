require 'yaml'

module Misty
  class Tags
    @data

    def initialize()
      load_tags
    end

    def get_tags( type )
      @data['tags'].select{|t| t['type'] == type }
    end

    def load_tags
      @data = YAML::load(File.read(format('%s/misty/tags.yml', LIB_DIR)))
    end
  end
end

