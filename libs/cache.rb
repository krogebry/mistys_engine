##
# Cache handler
##

module DevOps
  class Cache
    CACHE_TYPE_FILE = :file
    FS_CACHE_DIR = File.join('/', 'tmp', 'devops', 'cache')

    def initialize(cache_type=CACHE_TYPE_FILE)
      init_cache
    end

    def init_cache
      FileUtils.mkdir_p FS_CACHE_DIR
    end

    def del_key(key)
      system(format('rm -rf %s', File.join(FS_CACHE_DIR, key)))
    end

    def self.flush
      system(format('rm -rf %s/*', FS_CACHE_DIR))
    end

    def cached(key)
      fs_cache_file = File.join(FS_CACHE_DIR, key)
      FileUtils.mkdir_p(File.dirname(fs_cache_file)) unless File.exists?(File.dirname(fs_cache_file))
      if File.exists?(fs_cache_file)
        data = File.read(fs_cache_file)
      else
        Log.debug(format('Getting from source: %s', key).yellow)
        data = yield
        File.open(fs_cache_file, 'w') do |f|
          f.puts data
        end
      end
      data
    end

    def set(key, data)
      fs_cache_file = File.join(FS_CACHE_DIR, key)
      File.open(fs_cache_file, 'w') do |f|
        f.puts data
      end
    end

    def cached_json(key)
      fs_cache_file = File.join(FS_CACHE_DIR, key)
      FileUtils.mkdir_p(File.dirname(fs_cache_file)) unless File.exists?(File.dirname(fs_cache_file))
      if File.exists?(fs_cache_file)
        data = File.read(fs_cache_file)
      else
        Log.debug(format('Getting from source: %s', key).yellow)
        data = yield
        File.open(fs_cache_file, 'w') do |f|
          f.puts data
        end
      end

      begin
        JSON.parse(data)
      rescue JSON::ParserError => e
        return {}
      end
    end

  end
end
