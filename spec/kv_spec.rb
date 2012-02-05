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

  describe '#node' do
    it "returns a KV::Node object for a new node" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.class.should eq(KV::Node)
      n.name.should eq("test")
    end
  end
end # KV
