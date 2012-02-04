require "test_framework"
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
  end
end
