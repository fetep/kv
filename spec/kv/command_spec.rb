require "rspec/autorun"
require "spec_helper"
require "kv/command"

describe KV::Command do
  describe '#init' do
    it "should initialize a new kvdb" do
      $kvdb_path = File.join(@tmp_dir, "kvdb2")
      KV::Command.start(["init"])

      expect { KV.new(:path => $kvdb_path) }.should_not raise_error(KV::Error)
    end
  end

  describe '#list' do
    it "should list all nodes" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      expected = []
      3.times do |n|
        kv.node("test/#{n}")
        expected << "test/#{n}"
      end

      stdout, stderr = wrap_output do
        KV::Command.start(["list"])
      end
      stdout.should eq(expected.join("\n") + "\n")
    end

    it "should filter based on a regexp" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      expected = []
      kv.node("test/1")
      kv.node("foo/1")

      stdout, stderr = wrap_output do
        KV::Command.start(["list", "test/"])
      end
      stdout.should eq("test/1\n")
    end
  end

  describe '#nodepath' do
    it "should error given a non-existant node" do
      $kvdb_path = @kvdb_path

      stdout, stderr = wrap_output do
        expect do
          KV::Command.start(["nodepath", "foo/bar"])
        end.should raise_error(KV::Error, "foo/bar does not exist")
      end
      stdout.should eq('')
    end

    it "should print the full path to a node" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      n = kv.node("test")
      n.save

      stdout, stderr = wrap_output do
        KV::Command.start(["nodepath", "test"])
      end

      stdout.chomp.should eq(n.path)
    end
  end

  describe '#import' do
    it "should fail if the node already exists" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      n = kv.node("test")
      n.save

      stdout, stderr = wrap_output do
        expect do
          KV::Command.start(["import", "test", "/dev/null"])
        end.should raise_error(KV::Error, "test already exists")
      end
      stdout.should eq('')
    end

    it "should fail if the specified file does not exist" do
      $kvdb_path = @kvdb_path

      bad_path = File.join(@tmp_dir, "not", "here")
      stdout, stderr = wrap_output do
        expect do
          KV::Command.start(["import", "test", bad_path])
        end.should raise_error(KV::Error, "#{bad_path}: data file does not exist")
      end
      stdout.should eq('')
    end

    it "should load data from a file" do
      $kvdb_path = @kvdb_path

      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "key1: value1"
        f.puts "key1: value2"
        f.puts "key2: value"
      end

      stdout, stderr = wrap_output do
        KV::Command.start(["import", "test", data_file])
      end
      stdout.should eq('')

      kv = KV.new(:path => $kvdb_path)
      kv.node?("test").should eq(true)
      n = kv.node("test")
      n["key1"].should eq(["value1", "value2"])
      n["key2"].should eq("value")
    end
  end
end # describe KV::Node
