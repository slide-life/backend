require 'oj'
require 'active_support'

require_relative './camelize/key_map'

module Rack
  class Camelize
    using Rack::Camelize::KeyMap

    def initialize(app)
      @app = app
    end

    def call(env)
      process_as_snake(env)
      response = @app.call(env)
      return_as_camel(response)
    end

    private

    def process_as_snake(env)
      if env['CONTENT_TYPE'] == 'application/json'
        input = env['rack.input'].read
        env['rack.input'] = StringIO.new(to_snake(input))
      end
    end

    def return_as_camel(response)
      header, body = response[1], response[2]

      if header['Content-Type'] == 'application/json'
        body.map!(&method(:to_camel))
        header['Content-Length'] = body.map(&:bytesize).inject(0, :+).to_s
      end

      response
    end

    def to_snake(input)
      conversion = -> (x) { (x.is_a?(String) && !(x.include? ':')) ? x.underscore : x }
      Oj.dump(Rack::Camelize::KeyMap.fmap(conversion, Oj.load(input)))
    end

    def to_camel(output)
      conversion = -> (x) { (x.is_a?(String) && !(x.include? ':')) ? x.camelize(:lower) : x }
      Oj.dump(Rack::Camelize::KeyMap.fmap(conversion, Oj.load(output)))
    end
  end
end
