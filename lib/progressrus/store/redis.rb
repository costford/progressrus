module Progressrus
  module Store
    class Redis < Base
      attr_reader :redis
      attr_accessor :options

      def initialize(redis = ::Redis.new, options = {expire: 60 * 30, prefix: "progressrus"})
        @redis = redis
        @options = options
      end

      def persist(progresser)
        redis.hset(key(progresser.scope), progresser.id, progresser.to_serializeable.to_json)
        redis.expire(key(progresser.scope), options[:expire]) if options[:expire]
      end

      def scope(scope)
        scope = redis.hgetall(key(scope))
        scope.each_pair { |id, value|
          scope[id] = Tick.new(JSON.parse(value, symbolize_names: true))
        }
      end

      def find_all(scope)
        scope = redis.hgetall(key(scope))
        scope.collect { |id, value| Progresser.new(JSON.parse(value, symbolize_names: true))}
      end

      def find(scope, id)
        value = redis.hget(key(scope), id)
        Progresser.new(JSON.parse(value, symbolize_names: true))
      end

      def flush(scope, id = nil)
        if id
          redis.hdel(key(scope), id)
        else
          redis.del(key(scope))
        end
      end

      private
      def key(scope)
        "#{options[:prefix]}:#{scope.join(":")}"
      end
    end
  end
end
