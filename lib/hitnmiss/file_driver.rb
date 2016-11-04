require 'fileutils'

module Hitnmiss
  class FileDriver
    include Hitnmiss::Driver::Interface

    def self.init(folder)
      FileUtils.mkdir_p(folder)
    end

    def initialize(folder)
      @folder = File.expand_path(folder)
      self.class.init(@folder)
    end

    def set(key, entity)
      cache = { 'value' => entity.value }
      if entity.expiration
        expiration = epoch_time + entity.expiration
        cache['expiration'] = expiration
      end
      cache['fingerprint'] = entity.fingerprint if entity.fingerprint
      cache['updated_at'] = internal_timestamp
      cache['last_modified'] = entity.last_modified if entity.last_modified
      File.write(file_path(key), cache.to_json)
    end


    def get(key)
      cached_entity = read(file_path(key))

      return Hitnmiss::Driver::Miss.new if cached_entity.nil? || expired?(cached_entity)

      return Hitnmiss::Driver::Hit.new(cached_entity['value'],
                                       build_hit_keyword_args(cached_entity))
    end

    def expired?(entity)
      entity.has_key?('expiration') && epoch_time >= entity['expiration']
    end

    def all(keyspace)
      matching_values = []
      Dir["#{@folder}/*"].each do |filename|
        if match_keyspace?(File.basename(filename), keyspace)
          entity = read(filename)
          matching_values << entity['value'] if entity && !expired?(entity)
        end
      end
      return matching_values
    end

    def delete(key)
      File.unlink(file_path(key))
    end

    def clear(keyspace)
      Dir["#{@folder}/*"].each do |filename|
        File.unlink(filename) if match_keyspace?(File.basename(filename), keyspace)
      end
    end

    def file_path(key)
      File.join(@folder, key)
    end

    def read(file)
      if File.exist?(file)
        JSON.parse(File.read(file))
      else
        nil
      end
    end

    def match_keyspace?(key, keyspace)
      regex = Regexp.new("^#{keyspace}*")
      return regex.match(key)
    end

    def epoch_time
      Time.now.utc.to_i
    end

    def internal_timestamp
      Time.now.utc.iso8601
    end

    def build_hit_keyword_args(cached_entity)
      options = {}
      if cached_entity.has_key?('fingerprint')
        options[:fingerprint] = cached_entity['fingerprint']
      end
      if cached_entity.has_key?('updated_at')
        options[:updated_at] = Time.parse(cached_entity['updated_at'])
      end
      if cached_entity.has_key?('last_modified')
        options[:last_modified] = cached_entity['last_modified']
      end
      return **options
    end
  end
end
