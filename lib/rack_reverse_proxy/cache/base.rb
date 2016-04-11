module RackReverseProxy
  module Cache

    class Base

      def initialize(options = {})
        default_options = {
          prefix: "_rack_reverse_proxy.",
          timeout: 60, # seconds
        }
        @options = default_options.merge(options)
      end

      attr_reader :options

      def gen_key(uri)
        options[:prefix] + uri.to_s.gsub(/[:\.\/]/, "_")
      end

      def get(key)
      end

      def set(key, value)
      end

      def delete(key)
      end

      def clear
      end

    end

  end
end
