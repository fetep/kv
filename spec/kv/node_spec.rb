require "rspec/autorun"
require "spec_helper"
require "kv/node"

describe KV::Node do
  describe '#initialize' do
    it "should not error if the file does not exist" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test/1", node_path)
      n.attrs.to_hash.should eq({})
    end

    it "should properly load existing data from a file" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
        f.puts "key2: value2"
      end
      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value1")
      n["key2"].should eq("value2")
    end

    it "should throw KV::Error if the file is unreadable" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
        f.puts "key2: value2"
      end
      File.chmod(0, node_path)
      expect { KV::Node.new("test", node_path) }.should raise_error(KV::Error)
    end

  end # describe initialize

  describe "#load_data" do
    it "should properly load data from a file" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value: foo"
      end

      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value: foo")
    end
  end

  describe "#write_data" do
    it "should be able to write out single-value keys" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.set("key1", "value1")
      n.save

      File.read(node_path).split("\n").should eq(["key1: value1"])
    end

    it "should be able to write out multi-value keys" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.set("key1", ["value1", "value2"])
      n.save

      File.read(node_path).split("\n").should \
        eq(["key1: value1", "key1: value2"])
    end

    it "should create intermediate directories when saving a file" do
      node_path = File.join(@kvdb_path, "test", "foo1")
      n = KV::Node.new("test/foo1", node_path)
      n.save
      File.exists?(node_path).should eq(true)
    end
  end

  describe '#changed?' do
    it "should detect when the backing file mtime changes" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      # move the mtime back in time a bit so our update changes it
      File.utime(Time.now, Time.now - 10, node_path)
      n = KV::Node.new("test", node_path)

      File.open(node_path, "w+") do |f|
        f.puts "key2: value2"
      end
      n.changed?.should eq(true)
    end

    it "should handle starting with no file and discovering one" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)

      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      n.changed?.should eq(true)
    end

    it "should handle starting with a file that gets deleted" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      n = KV::Node.new("test", node_path)

      File.unlink(node_path)
      n.changed?.should eq(true)
    end
  end # describe changed?

  describe '#reload' do
    it "should reload all data when file changes" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      # move the mtime back in time a bit so our update changes it
      File.utime(Time.now, Time.now - 10, node_path)
      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value1")

      File.open(node_path, "w+") do |f|
        f.puts "key2: value2"
      end
      n.reload
      n["key1"].should eq(nil)
      n["key2"].should eq("value2")
    end

    it "should clear data when a file is removed" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value1")

      File.unlink(node_path)
      n.reload
      n.attrs.to_hash.should eq({})
    end

    it "should discover and load a new file" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.attrs.to_hash.should eq({})

      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      n.reload
      n["key1"].should eq("value1")
    end
  end

  # really testing we're calling KV::Node::Attrs#set, more tests in attrs_spec.
  describe '#set' do
    it "should handle setting a String value" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.set("foo", "bar")
      n.set("foo", "bar")
      n["foo"].should eq("bar")
    end

    it "should handle setting an Array value" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.set("foo", ["bar1", "bar2"])
      n["foo"].should eq(["bar1", "bar2"])
    end
  end

  # really testing we're calling KV::Node::Attrs#add, more tests in attrs_spec.
  describe '#add' do
    it "should handle setting a String value" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.add("foo", "bar")
      n["foo"].should eq("bar")
    end

    it "should handle appending a String value" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.add("foo", "bar1")
      n["foo"].should eq("bar1")
      n.add("foo", "bar2")
      n["foo"].should eq(["bar1", "bar2"])
    end
  end

  describe '#save' do
    it "should write an updated data file if one already exists" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      n = KV::Node.new("test", node_path)
      n.set("key2", "value2")
      n.save

      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value1")
      n["key2"].should eq("value2")
    end

    it "should write an updated data file if it does not exist" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.set("key1", "value1")
      n.save

      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value1")
    end
  end

  describe "#delete" do
    it "should delete existing keys" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.add("key1", "value1")
      n.add("key1", "value2")
      n.delete("key1")
      n["key1"].should eq(nil)
    end
  end # describe #delete
end # describe KV::Node
