# frozen_string_literal: true

require 'net/http'
module DiscourseGitcoinPassport
  class ApiClient
    BASE_URL = 'https://api.scorer.gitcoin.co/registry'.freeze

    def initialize(api_key, scorer_id)
      @api_key = api_key
      @scorer_id = scorer_id
    end

    def submit_passport(address)
      uri = URI("#{BASE_URL}/submit-passport")
      request = Net::HTTP::Post.new(uri,
        'Content-Type' => 'application/json',
        'X-API-KEY' => @api_key)
      request.body = { address: address, scorer_id: @scorer_id }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      result = check_response(response)
      process_response(result, address)
    end

    def get_score(address, delay_seconds = 1)
      uri = URI("#{BASE_URL}/score/#{@scorer_id}/#{address}")
      request = Net::HTTP::Get.new(uri,
        'X-API-KEY' => @api_key)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      result = check_response(response)
      process_response(result, address, delay_seconds)
    end

    private

    def process_response(result, address, delay_seconds = 1)
      if result['status'] == 'PROCESSING'
        sleep(delay_seconds)
        delay_seconds *= 2
        if delay_seconds > 8
          false
        else
          get_score(address, delay_seconds)
        end
      else
        result
      end
    end

    def check_response(response)
      raise "Unexpected response: #{response.code} - #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise "Invalid JSON returned by server"
    end
  end
end