require 'spec_helper'
require 'json'

describe Risebox::Client::Session do

  subject { Risebox::Client::Session.new('id', 'token', nil, false) }

  describe '#initialize' do
    it 'creates a new Client service object with given key and secret' do
      subject.key.should eq 'id'
      subject.secret.should eq 'token'
    end
  end

  describe '#api_get and #api_post' do
    before do
      @headers = { 'RISEBOX-SECRET' => subject.secret, 'Accept' => 'application/json'}
    end
    describe '#api_get' do
      before do
        url                        = 'https://risebox-api.herokuapp.com/api/some/url?context=some,data'
        paginated_url              = 'https://risebox-api.herokuapp.com/api/some/url?context=some,data&page=3'
        @stubbed_request           = stub_request(:get, url).with(headers: @headers)
        @stubbed_paginated_request = stub_request(:get, paginated_url).with(headers: @headers)
      end

      it 'makes an HTTP request to the given url using its credentials and forwarding the given options params' do
        @stubbed_request.to_return(status: 200, body:   {result: ['two', 'contents'], sections: ['two', 'sections']}.to_json)
        @stubbed_paginated_request.to_return(status: 200, body:   {result: ['page 3', 'contents'], sections: ['two', 'sections']}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [true, {result: ['two', 'contents'], sections: ['two', 'sections']}]
        subject.send(:api_get, '/api/some/url', context: [:some, :data], page: 3).should eq [true, {result: ['page 3', 'contents'], sections: ['two', 'sections']}]
      end

      it 'returns error with message when WS replies with 403' do
        @stubbed_request.to_return(status: 403, body: {message: 'no channel matching your credentials'}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'no channel matching your credentials'}]
      end

      it 'returns error with message when WS replies with 404' do
        @stubbed_request.to_return(status: 404, body: {message: 'no channel with this prefix'}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'no channel with this prefix'}]
      end

      it 'returns WS message when WS replies with 500' do
        @stubbed_request.to_return(status: 500, body:   {message: 'an error occurred'}.to_json)

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'an error occurred'}]
      end

      it 'returns timeout message when WS timeout' do
        @stubbed_request.to_timeout

        subject.send(:api_get, '/api/some/url', context: [:some, :data]).should eq [false, {message: 'Timeout'}]
      end

      it 'does not call the API and returns a curl command if only_curl: true is passed in the options' do
        @stubbed_paginated_request.should_not have_been_requested

        subject.send(:api_get, '/api/some/url', context: [:some, :data], page: 3, only_curl: true)
               .should eq [true, "curl -X GET 'https://risebox-api.herokuapp.com/api/some/url?context=some%2Cdata&page=3' -H 'Accept:application/json' -H 'Accept-Language:' -H 'RISEBOX-SECRET:token' -i"]
      end

      context 'given a session in raise_error mode' do
        before do
          @client = Risebox::Client::Session.new('id', 'token', nil)
        end

        it 'returns only the API response body, without splatting with a success flag' do
          @stubbed_request.to_return(status: 200, body:   {result: ['two', 'contents'], sections: ['two', 'sections']}.to_json)

          @client.send(:api_get, '/api/some/url', context: [:some, :data]).should eq({result: ['two', 'contents'], sections: ['two', 'sections']})
        end

        it 'raises a Risebox exception when WS replies with 443' do
          @stubbed_request.to_return(status: 403, body: {message: 'No channel matches your credentials'}.to_json)

          expect { @client.send(:api_get, '/api/some/url', context: [:some, :data]) }.to raise_error(Risebox::Client::ForbiddenError)
        end

        it 'raises a Risebox exception when WS replies with 404' do
          @stubbed_request.to_return(status: 404, body: {message: 'no channel with this prefix'}.to_json)

          expect { @client.send(:api_get, '/api/some/url', context: [:some, :data]) }.to raise_error(Risebox::Client::NotFoundError)
        end

        it 'raises a Risebox exception when WS replies with 500' do
          @stubbed_request.to_return(status: 500, body: {message: 'an error occurred'}.to_json)

          expect { @client.send(:api_get, '/api/some/url', context: [:some, :data]) }.to raise_error(Risebox::Client::AppError)
        end

        it 'raises a Risebox exception timeout when WS timeout' do
          @stubbed_request.to_timeout

          expect {@client.send(:api_get, '/api/some/url', context: [:some, :data])}.to raise_error(Risebox::Client::TimeoutError)
        end
      end
    end

    describe '#post_api' do
      before do
        url              = 'https://risebox-api.herokuapp.com/api/some/url?context=some,data'
        @post_params      = {'content' => {'title' => 'my title', 'body' => 'my body'}}
        @stubbed_request = stub_request(:post, url).with(headers: @headers, body: @post_params)
      end

      it 'makes an HTTP request to the given url using its credentials and forwarding the given options params' do
        @stubbed_request.to_return(status: 200, body:   {result: ['two', 'contents'], sections: ['two', 'sections']}.to_json)

        subject.send(:api_post, '/api/some/url', @post_params, context: [:some, :data]).should eq [true, {result: ['two', 'contents'], sections: ['two', 'sections']}]
      end
    end

  end

  describe '#metric_measures' do
    it 'makes an api call to /api/device/:key/metrics/:metric/measures passing the context in query string' do
      subject.stub(:api_get).with('/api/device/id/metrics/ph/measures', context: [:device, :html]).and_return([true, {measures: 'data'}])

      subject.metric_measures('ph', context: [:device, :html]).should eq [true, {measures: 'data'}]
    end
  end

  describe '#send_measure' do
    it 'makes an api post call to /api/device/:id/metrics/:metric/measures passing the content in query string' do
      subject.stub(:api_post).with('/api/device/id/metrics/ph/measures', {value: '7'}, {context: [:device, :html]}).and_return([true, {measure: 'data'}])

      subject.send_measure('ph', '7', context: [:device, :html]).should eq [true, {measure: 'data'}]
    end
  end

end