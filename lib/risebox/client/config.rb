module Risebox
  module Client
    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end

    class Configuration
      attr_accessor :api_url

      def initialize
        @api_url = 'https://rbdev-api.herokuapp.com'
      end
    end
  end
end