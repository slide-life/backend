module Rack
  class Camelize
    module KeyMap
      def self.fmap(function, data)
        case data
          when Hash
            Hash[data.map { |k, v| [function.call(k), fmap(function, v)] }]
          when Array
            data.map { |x| fmap(function, x) }
          else
            data
        end
      end

      def self.map_values(function, data)
        case data
          when Hash
            Hash[data.map { |k, v| [k, map_values(function, v)] }]
          when Array
            data.map { |x| map_values(function, x) }
          else
            function.call(data)
        end
      end
    end
  end
end
