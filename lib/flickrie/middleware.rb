require 'faraday'
require 'faraday_middleware/response_middleware'

module Flickrie
  class Error < StandardError
    attr_reader :code

    def initialize(message, code = nil)
      super(message)
      @code = code.to_i
    end
  end

  # Internal
  module Middleware # :nodoc:
    class StatusCheck < Faraday::Response::Middleware
      def on_complete(env)
        if env[:body]['stat'] != 'ok'
          raise Error.new(env[:body]['message'], env[:body]['code'])
        end
      end
    end

    class UploadStatusCheck < Faraday::Response::Middleware
      def on_complete(env)
        if env[:body]['rsp']['stat'] != 'ok'
          error = env[:body]['rsp']['err']
          raise Error.new(error['msg'], error['code'])
        end
      end
    end

    class OAuthCheck < Faraday::Response::Middleware
      def on_complete(env)
        if env[:status] != 200
          message = env[:body][/(?<=oauth_problem=)[^&]+/]
          pretty_message = message.gsub('_', ' ').capitalize
          raise Error.new(pretty_message)
        end
      end
    end

    class Retry < Faraday::Middleware
      def initialize(app, retries = 2)
        @retries = retries
        super(app)
      end

      def call(env)
        retries = @retries
        begin
          @app.call(env)
        rescue Faraday::Error::TimeoutError
          if retries > 0
            retries -= 1
            retry
          end
          raise
        end
      end
    end

    class ParseOAuthParams < FaradayMiddleware::ResponseMiddleware
      define_parser do |body|
        CGI.parse(body).inject({}) do |hash, (key, value)|
          hash.update(key.to_sym => value.first)
        end
      end
    end
  end
end
