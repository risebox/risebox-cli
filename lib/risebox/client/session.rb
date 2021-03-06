module Risebox
  module Client
    class Session

      include Risebox::Client::Connection

      attr_reader :key, :secret, :locale

      def initialize key, secret, locale, raise_errors=true
        @key    = key
        @secret = secret
        @locale = locale
        @raise  = raise_errors
      end

      def metrics options={}
        api_get "/api/devices/#{key}/metrics", options
      end

      def metric_measures metric, options={}
        api_get "/api/devices/#{key}/metrics/#{metric}/measures", options
      end

      def send_measure metric, value, options={}
        api_post "/api/devices/#{key}/metrics/#{metric}/measures", {value: value}, options
      end

      def send_alert metric, value, description, options={}
        api_post "/api/devices/#{key}/metrics/#{metric}/alerts", {value: value, description: description}, options
      end


    private

      def api_get url, options
        api_call :get, url, nil, options
      end

      def api_post url, form_params, options
        api_call :post, url, form_params, options
      end

      def api_call verb, url, form_params, options
        conn   = get_connection(url: Risebox::Client.configuration.api_url)

        context = (options[:context].join(',') if options[:context].respond_to?(:join))
        (conn.params['context'] = context         ) if context
        (conn.params['page']    = options[:page]  ) if options[:page] && options[:page] != ''

        conn.headers['Accept']          = 'application/json'
        conn.headers['Accept-Language'] = locale.to_s if locale
        conn.headers['RISEBOX-SECRET']  = secret.to_s

        if options[:only_curl]
          api_curl_command verb, conn, url, form_params
        else
          if @raise
            perform_request!(verb, conn, url, form_params)
          else
            perform_request(verb, conn, url, form_params)
          end
        end
      end

      def api_curl_command verb, conn, url, form_params
        [true, "curl -X #{verb.to_s.upcase} '#{conn.build_url(url)}' -H 'Accept:#{conn.headers['Accept']}' -H 'Accept-Language:#{conn.headers['Accept-Language']}' -H 'RISEBOX-SECRET:#{conn.headers['RISEBOX-SECRET']}' -i"]
      end
    end
  end
end