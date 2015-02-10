require 'faraday'

module Risebox
  module Client
    module Connection

      def get_connection args
        Faraday.new(args)
      end

      def perform_request verb, conn, url, form_params=nil
        begin
          result = http_call(verb, conn, url, form_params)
        rescue Faraday::Error::TimeoutError
          return [false, message: 'Timeout']
        end
        case result.status
        when 200
          [true, sym_keys(JSON.parse(result.body))]
        when 403
          [false, sym_keys(JSON.parse(result.body))]
        when 404
          [false, sym_keys(JSON.parse(result.body))]
        when 500
          [false, sym_keys(JSON.parse(result.body))]
        end
      end

      def perform_request! verb, conn, url, form_params=nil
        begin
          result = http_call(verb, conn, url, form_params)
        rescue Faraday::Error::TimeoutError
          raise Risebox::Client::TimeoutError, 'Risebox Client Timeout'
        end
        case result.status
        when 200
          sym_keys(JSON.parse(result.body))
        when 403
          raise Risebox::Client::ForbiddenError, 'Risebox Client Bad credentials'
        when 404
          raise Risebox::Client::NotFoundError, 'Risebox Client Ressource not found'
        when 500
          raise Risebox::Client::AppError, 'Risebox Client Application error'
        end
      end

    private
      def http_call verb, conn, url, form_params=nil
        result = conn.public_send(verb) do |req|
          req.url url
          req.body = form_params if verb == :post
          req.options[:timeout]       = 5
          req.options[:open_timeout]  = 2
        end
      end

      def sym_keys hash
        transfo_keys hash do |key|
          key.to_sym rescue key
        end
      end

      def transfo_keys hash, &block
        hash.keys.each do |key|
          hash[yield(key)] = hash.delete(key)
        end
        hash
      end
    end
  end
end