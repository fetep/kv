require "rspec/autorun"
require "spec_helper"
require "kv/node/attrs"

describe KV::Node::Attrs do
  describe "#add" do
    it "should create a key with specified value if one does not exist" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n["key1"].should eq(nil)
      n.add("key1", "value1")
      n["key1"].should eq("value1")
    end

    it "should turn a single value into an array" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.add("key1", "value1")
      n["key1"].should eq("value1")
      n.add("key1", "value2")
      n["key1"].should eq(["value1", "value2"])
    end

    it "should append to an array" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.add("key1", "value1")
      n.add("key1", "value2")
      n["key1"].should eq(["value1", "value2"])
      n.add("key1", "value3")
      n["key1"].should eq(["value1", "value2", "value3"])
    end

    it "should throw a KV::Error given an invalid key" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      expect { n.add("#key1", "value1") }.should raise_error(KV::Error)
    end

    it "should throw a KV::Error given a a non-String key" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      expect { n.add(:key1, "value1") }.should raise_error(KV::Error)
    end

    it "should bail on a non-String value" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      expect { n.add("key1", :value1) }.should raise_error(KV::Error)
    end
  end # describe #add

  describe "#set" do
    it "should take a string" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.set("key1", "value1")
      n["key1"].should eq("value1")
    end

    it "should take an array" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.set("key1", ["value1", "value2"])
      n["key1"].should eq(["value1", "value2"])
    end

    it "should bail on a non-String/Array value" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      expect { n.set("key1", :value1) }.should raise_error(KV::Error)
    end

    it "should bail on an array with a non-String element" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      expect { n.set("key1", ["value1", :value2]) }.should raise_error(KV::Error)
    end

    it "should throw a KV::Error given an invalid key" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      expect { n.set("#key1", "value1") }.should raise_error(KV::Error)
    end

    it "should throw a KV::Error given a non-String key" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      expect { n.set(:key1, "value1") }.should raise_error(KV::Error)
    end
  end # describe #add

  describe "#[]=" do
    it "should call set" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.attrs["key1"] = "value1"
      n.attrs["key1"] = "value2"
      n.attrs["key1"].should eq("value2")
    end
  end
end # describe KV::Node
