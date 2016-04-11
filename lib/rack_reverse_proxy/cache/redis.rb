require "redis"
require "yaml"

module RackReverseProxy
  module Cache

    class Redis < Base

      def initialize(options={})
        default_options = {
          url: nil
        }
        super(default_options.merge(options))
        @client = ::Redis.new(url: options[:url])
      end

      def get(key)
        result = @client.get(key)
        return YAML.load(result) unless result.nil?
        result
      end

      def set(key, value)
        @client.set(key, YAML.dump(value), timeout: options[:timeout])
      end

    end

  end
end
