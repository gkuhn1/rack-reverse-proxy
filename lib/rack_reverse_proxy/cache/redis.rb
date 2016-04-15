require "redis"
require "redis-store"
require "connection_pool"
require "yaml"

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
        return YAML.load(result) unless result.nil?
        result
      end

      def set(key, value)
        with { |c| c.set(key, YAML.dump(value), timeout: options[:timeout]) }
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
