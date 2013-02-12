require 'sinatra/base'
require 'redis'
require 'uri'
require 'json'

module Corginator
  class Storage
    def count
      redis.scard("corgis")
    rescue Redis::CannotConnectError
      0
    end

    def random(count = 1)
      redis.srandmember("corgis", count)
    rescue Redis::CannotConnectError
      []
    end

    def redis
      @redis ||= Redis.new(:host => redis_uri.host, :port => redis_uri.port)
    end

    def redis_uri
      @uri ||= URI.parse(ENV['REDIS_URI'] || 'localhost:6379')
    end
  end

  class Web < Sinatra::Base
    attr_reader :storage

    def initialize
      super
      @storage = Corginator::Storage.new
    end

    get '/' do
      "Here be corgis"
    end

    get '/random' do
      corgi = storage.random
      json_respond :corgi => corgi.delete_at(0).to_s
    end

    get '/bomb' do
      corgis = storage.random(count)
      json_respond :corgis => corgis
    end

    get '/count' do
      count = storage.count
      json_respond :count => count
    end

    def count
      if params[:count].nil? || params[:count].to_i == 0
        5
      else
        params[:count].to_i
      end
    end

    def json_respond(resp)
      content_type :json
      JSON.dump(resp)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Corginator::Web.run!
end
