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
    end
  end
end
