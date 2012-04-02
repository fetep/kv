require "rubygems"
require "json"

require "rspec/autorun"
require "spec_helper"
require "kv"

describe KV do
  describe ".create_kvdb" do
    it "creates a kvdb directory and initial .kvdb" do
      # before(:each) hook is calling .create_kvdb
      File.directory?(@kvdb_path).should eq(true)
      File.exists?(@kvdb_metadata_path).should eq(true)

      kvdb_metadata = JSON.parse(File.read(@kvdb_metadata_path))
      kvdb_metadata["version"].should eq("1")
      kvdb_metadata["mapping"].should eq({})
    end

    context "when given an invalid directory" do
      it "refuses to create a kvdb" do
        expect { KV.create_kvdb(@kvdb_path) }.should raise_error(KV::Error)
      end
    end
  end # .create_kvdb

  describe "#initialize" do
    it "throws KV::Error when :path doesn't exist" do
      expect { KV.new({}) }.should raise_error(KV::Error)
    end

    it "throws KV::Error when metadata is absent" do
      expect { KV.new(:path => @tmp_dir) }.should raise_error(KV::Error)
    end
  end

  describe '#load_metadata' do
    it "can read the default metadata written" do
      kv = KV.new(:path => @kvdb_path)
    end

    it "throws KV::Error when metadata is unparsable JSON" do
      File.open(@kvdb_metadata_path, "w+") { |f| f.puts "{'" }
      expect { KV.new(:path => @kvdb_path) }.should raise_error(KV::Error)
    end

    it "throws KV::Error when metadata is missing a version" do
      kvdb_metadata = { "versionX" => "1", "mapping" => {} }
      File.open(@kvdb_metadata_path, "w+") { |f| f.puts kvdb_metadata.to_json  }

      expect { KV.new(:path => @kvdb_path) }.should raise_error(KV::Error)
    end

    it "throws KV::Error when metadata is missing a mapping" do
      kvdb_metadata = { "version" => "1", "mappingX" => {} }
      File.open(@kvdb_metadata_path, "w+") { |f| f.puts kvdb_metadata.to_json  }

      expect { KV.new(:path => @kvdb_path) }.should raise_error(KV::Error)
    end

    it "throws KV::Error when metadata has a mapping that is not a hash" do
      kvdb_metadata = { "version" => "1", "mapping" => [] }
      File.open(@kvdb_metadata_path, "w+") { |f| f.puts kvdb_metadata.to_json  }

      expect { KV.new(:path => @kvdb_path) }.should raise_error(KV::Error)
    end

    it "throws KV::Error when metadata is not version 1" do
      kvdb_metadata = { "version" => "2", "mapping" => {} }
      File.open(@kvdb_metadata_path, "w+") { |f| f.puts kvdb_metadata.to_json  }

      expect { KV.new(:path => @kvdb_path) }.should raise_error(KV::Error)
    end
  end

  describe '#load_metadata' do
    it "writes updated metadata" do
      kv = KV.new(:path => @kvdb_path)
      path = kv.node_path("test")

      kvdb_metadata = JSON.parse(File.read(@kvdb_metadata_path))
      kvdb_metadata["mapping"]["test"].should eq(path)
    end
  end

  describe '#node_path' do
    it "returns an existing mapping if one exists" do
      node_path = File.join(@kvdb_path, "test")
      kvdb_metadata = JSON.parse(File.read(@kvdb_metadata_path))
      kvdb_metadata["mapping"]["test"] = node_path
      File.open(@kvdb_metadata_path, "w+") do |f|
        f.puts kvdb_metadata.to_json
      end

      kv = KV.new(:path => @kvdb_path)
      kv.node_path("test").should eq(node_path)
    end

    it "returns a fully-qualified path for a new node file" do
      kv = KV.new(:path => @kvdb_path)
      kv.node_path("test").index(@kvdb_path).should eq(0)
    end
  end

  describe '#node' do
    it "returns a KV::Node object for a new node" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.class.should eq(KV::Node)
      n.name.should eq("test")
    end

    it "returns a KV::Node object loaded with data" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end

      kvdb_metadata = JSON.parse(File.read(@kvdb_metadata_path))
      kvdb_metadata["mapping"]["test"] = node_path
      File.open(@kvdb_metadata_path, "w+") do |f|
        f.puts kvdb_metadata.to_json
      end

      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n["key1"].should eq("value1")
    end

    it "should return the same KV::Node object" do
      kv = KV.new(:path => @kvdb_path)
      n1 = kv.node("test")
      n1.set("key1", "value1")
      n2 = kv.node("test")
      n2.object_id.should eq(n1.object_id)
      n2["key1"].should eq(n1["key1"])
    end
  end

  describe '#node?' do
    it "should return false if a node does not exist in mapping" do
      kv = KV.new(:path => @kvdb_path)
      kv.node?("test").should eq(false)
    end

    it "should return false if a node is in mapping and has a data file" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.save
      kv.node?("test").should eq(true)
    end
  end

  describe '#nodes' do
    it "should return an array of all available nodes" do
      kv = KV.new(:path => @kvdb_path)
      kv.node("test/1")
      kv.node("test/2")
      kv.node("test/3")
      kv.nodes.should eq(["test/1", "test/2", "test/3"])
    end
  end

  describe '#expand' do
    it "should list all node attributes given a valid node name" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.set("key1", ["value1", "value2"])
      n.set("key2", "value")
      n.save

      kv.expand("test").should eq([
        "test#key1#0: value1",
        "test#key1#1: value2",
        "test#key2: value",
        ])
    end

    it "should raise an exception if the node_name does not exist" do
      kv = KV.new(:path => @kvdb_path)
      expect { kv.expand("test") }.should \
             raise_error(KV::Error, "node test does not exist")
    end

    it "should return [] if the node does not exist and raise_on_bad_node_name is false" do
      kv = KV.new(:path => @kvdb_path)
      kv.expand("test", false, false).should eq([])
    end

    it "should show just the value when given a full keypath" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.set("key1x", ["value1", "value2"])
      n.set("key2", "value")
      n.save

      kv.expand("test#key1x").should eq([
        "value1",
        "value2",
        ])
      kv.expand("test#key2").should eq([
        "value",
        ])
    end

    it "should show the keypath and value when given a full keypath and verbose is true" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.set("key1", ["value1", "value2"])
      n.set("key2", "value")
      n.save

      kv.expand("test#key1", true).should eq([
        "test#key1#0: value1",
        "test#key1#1: value2",
        ])
      kv.expand("test#key2", true).should eq([
        "test#key2: value",
        ])
    end

    it "should list all node attributes given a valid node name" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.set("key1", ["value1", "value2"])
      n.set("key2", "value")
      n.save

      kv.expand("test").should eq([
        "test#key1#0: value1",
        "test#key1#1: value2",
        "test#key2: value",
        ])
    end
  end

  describe '#delete' do
    it "should fail to delete a node that does not exist" do
      kv = KV.new(:path => @kvdb_path)
      expect do
        kv.delete("test/1")
      end.should raise_error(KV::Error, "node test/1 does not exist")
    end

    it "should delete an existing node" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("foo", "bar")
      n.save
      kv.node?("test/1").should eq(true)

      kv.delete("test/1")
      kv.node?("test/1").should eq(false)
    end
  end
end # KV
