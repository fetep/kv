require "rubygems"
require "json"
require "sinatra"

class KVD
  class Web < Sinatra::Base
    @@ferret_index = nil

    public
    def self.ferret_index=(ferret_index)
      @@ferret_index = ferret_index
    end

    public
    def initialize(*a)
      if @@ferret_index.nil?
        raise "must set KVD::Web.ferret_index"
      end

      super
    end # def initialize

    get '/' do
      "<form method=get action=/search>" +
      "q=<input type=text name=q length=80><br>" +
      "f=<input type=text name=f length=30><br>" +
      "</form>"
    end

    get '/search' do
      content_type "application/json"

      res = []
      @@ferret_index.search_each(params[:q]) do |id, score|
        res << @@ferret_index[id]["__kvdb_node"]
      end

      return res.to_json
    end
  end # class Web
end # class KVD
