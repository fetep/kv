require "rspec/autorun"
require "spec_helper"
require "kv/node"

describe KV::Node do
  describe '#initialize' do
    it "should not error if the file does not exist" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test/1", node_path)
      n.attrs.should eq({})
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

  describe "#load_attrs" do
    it "should handle values with colons" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value: foo"
      end
      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value: foo")
    end

    it "should skip comments" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
        f.puts "#key2: value2"
      end
      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value1")
      n["key2"].should eq(nil)
      n["#key2"].should eq(nil)
    end

    it "should skip blank lines" do
      node_path = File.join(@kvdb_path, "test")
      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
        f.puts ""
        f.puts "key2: value2"
      end
      n = KV::Node.new("test", node_path)
      n["key1"].should eq("value1")
      n["key2"].should eq("value2")
      n.attrs.keys.sort.should eq(["key1", "key2"])
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
      n.attrs.should eq({})
    end

    it "should discover and load a new file" do
      node_path = File.join(@kvdb_path, "test")
      n = KV::Node.new("test", node_path)
      n.attrs.should eq({})

      File.open(node_path, "w+") do |f|
        f.puts "key1: value1"
      end
      n.reload
      n["key1"].should eq("value1")
    end
  end
end # describe KV::Node
