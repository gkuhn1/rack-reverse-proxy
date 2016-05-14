require "redis"
require "redis-store"
require "connection_pool"
require "yaml"
require "zlib"

module RackReverseProxy
  module Cache

    class Redis < Base

      def initialize(options={})
        default_options = {
          url: nil,
          pool: nil,
          pool_size: nil,
          pool_timeout: nil,
          redis_store: nil
        }
        super(default_options.merge(options))
        @pooled = false
        @client = if options[:pool]
                    raise "pool must be an instance of ConnectionPool" unless options[:pool].is_a?(::ConnectionPool)
                    @pooled = true
                    options[:pool]
                  elsif [:pool_size, :pool_timeout].any? { |key| options.has_key?(key) }
                      pool_options           = {}
                      pool_options[:size]    = options[:pool_size] if options[:pool_size]
                      pool_options[:timeout] = options[:pool_timeout] if options[:pool_timeout]
                      @pooled = true
                      ::ConnectionPool.new(pool_options) { ::Redis::Store::Factory.create(options[:url]) }
                  else
                    options.has_key?(:redis_store) ?
                      options[:redis_store] :
                      ::Redis::Store::Factory.create(options[:url])
                  end
      end

      attr_reader :client

      def get(key)
        result = with { |c| c.get(key) }
        return YAML.load(Zlib::Inflate.inflate(result)) unless result.nil?
        result
      end

      def set(key, value)
        yml_data = YAML.dump(value)
        with { |c|
          c.set(key, Zlib::Deflate.deflate(yml_data))
          c.expire(key, options[:timeout])
        }
      end

      def with(&block)
        if @pooled
          client.with(&block)
        else
          block.call(client)
        end
      end

    end

  end
end
