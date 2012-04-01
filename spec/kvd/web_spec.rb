require "rspec/autorun"
require "spec_helper"
require "kvd/indexer"
require "kvd/web"
require "rack/test"

describe KVD::Web do
  include Rack::Test::Methods

  def app
    kv = KV.new(:path => @kvdb_path)
    n = kv.node("test/1")
    n.set("foo", "bar")
    n.save

    i = KVD::Indexer.new(kv)
    KVD::Web.ferret_index = i.index
    return KVD::Web
  end

  describe 'get /' do
    it "should return 200" do
      get '/'
      last_response.should be_ok
    end
  end # describe get /
end # describe KVD::Web
