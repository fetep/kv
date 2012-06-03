require "rspec/autorun"
require "spec_helper"
require "kvd/indexer"

Thread::abort_on_exception = true

describe KVD::Indexer do
  before do
    @kv = KV.new(:path => @kvdb_path)
    n = @kv.node("test/1")
    n.set("foo", "bar")
    n.save
    n = @kv.node("test/2")
    n.set("foo", "baz")
    n.save
    n = @kv.node("test/3")
    n.set("foo", "bar")
    n.save
    @i = KVD::Indexer.new(@kv)
  end

  describe "#initialize" do
    it "should index all existing nodes" do
      res = {}
      @i.index.search_each("*", :limit => :all) do |doc, score|
        res[@i.index[doc]["_node"]] = @i.index[doc]["foo"]
      end

      res.should eq({"test/1" => "bar", "test/2" => "baz", "test/3" => "bar"})
    end

    it "should index all node attributes" do
      res = {}
      @i.index.search_each("foo: bar", :limit => :all) do |doc, score|
        res[@i.index[doc]["_node"]] = @i.index[doc]["foo"]
      end

      res.should eq({"test/1" => "bar", "test/3" => "bar"})
    end
  end # describe #initialize

  describe "#watch" do
    before do
      @watch_thread = Thread.new { @i.watch }
    end

    it "should notice a new node" do
      kv = KV.new(:path => @kvdb_path)
      node = kv.node("test/new1")
      node.set("foo", "baz")
      node.save

      try = 0
      while try <= 3 and sleep(0.2) # let inotify event fire & get processed
        try += 1

        res = {}
        @i.index.search_each("*", :limit => :all) do |doc, score|
          res[@i.index[doc]["_node"]] = @i.index[doc]["foo"]
        end

        break if res.keys.sort == ["test/1", "test/2", "test/3", "test/new1"]
      end

      res.keys.sort.should eq(["test/1", "test/2", "test/3", "test/new1"])
    end

    it "should notice a deleted node" do
      kv = KV.new(:path => @kvdb_path)
      kv.delete("test/1")

      try = 0
      while try <= 3 and sleep(0.2) # let inotify event fire & get processed
        try += 1

        res = {}
        @i.index.search_each("*", :limit => :all) do |doc, score|
          res[@i.index[doc]["_node"]] = @i.index[doc]["foo"]
        end

        break if res.keys.sort == ["test/2", "test/3"]
      end

      res.keys.sort.should eq(["test/2", "test/3"])
    end

    it "should notice changes in an existing node" do
      kv = KV.new(:path => @kvdb_path)
      node = kv.node("test/2")
      node.set("foo", "bar")
      node.save

      try = 0
      while try <= 3 and sleep(0.2) # let inotify event fire & get processed
        try += 1

        res = {}
        @i.index.search_each("foo: bar", :limit => :all) do |doc, score|
          res[@i.index[doc]["_node"]] = @i.index[doc]["foo"]
        end

        break if res.keys.sort == ["test/1", "test/2", "test/3"]
      end

      res.keys.sort.should eq(["test/1", "test/2", "test/3"])
    end

    it "should handle arrays" do
      kv = KV.new(:path => @kvdb_path)
      node = kv.node("test/2")
      node.add("foo", "bar")
      node.save

      try = 0
      while try <= 3 and sleep(0.2) # let inotify event fire & get processed
        try += 1

        res = {}
        @i.index.search_each("foo: bar", :limit => :all) do |doc, score|
          res[@i.index[doc]["_node"]] = @i.index[doc]["foo"]
        end

        break if res.keys.sort == ["test/1", "test/2", "test/3"]
      end

      res.keys.sort.should eq(["test/1", "test/2", "test/3"])

      res = {}
      @i.index.search_each("foo: baz", :limit => :all) do |doc, score|
        res[@i.index[doc]["_node"]] = @i.index[doc]["foo"]
      end
      res.keys.sort.should eq(["test/2"])
    end
  end
end # describe KVD::Web
