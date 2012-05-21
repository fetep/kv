require "rspec/autorun"
require "spec_helper"
require "kv/audit"

describe KV::Audit::Config do
  describe '#initialize' do
    it "should parse a schema file in kvdb root" do
      schema_file = File.join(@kvdb_path, "schema")
      File.open(schema_file, "w+") { |f| f.puts %q{
            nodes "host/*" do
                required "test" => [:single_value]
            end
} }

      kv = KV.new(:path => @kvdb_path)
      config = KV::Audit::Config.new(kv).for("host/foo")
      config[:required].should eq(["test"])
      config[:validate].keys.should eq(["test"])
    end

    it "should set required without validation functions" do
      schema_file = File.join(@kvdb_path, "schema")
      File.open(schema_file, "w+") { |f| f.puts %q{
            nodes "host/*" do
                required "test" => []
            end
} }

      kv = KV.new(:path => @kvdb_path)
      config = KV::Audit::Config.new(kv).for("host/foo")
      config[:required].should eq(["test"])
      config[:validate].should eq({})
    end

    it "should set required with validation functions" do
      schema_file = File.join(@kvdb_path, "schema")
      File.open(schema_file, "w+") { |f| f.puts %q{
            nodes "host/*" do
                required "test" => [:single_value]
            end
} }

      kv = KV.new(:path => @kvdb_path)
      config = KV::Audit::Config.new(kv).for("host/foo")
      config[:required].should eq(["test"])
      config[:validate].keys.should eq(["test"])
      config[:validate]["test"].length.should eq(1)
      config[:validate]["test"][0].length.should eq(2)
      config[:validate]["test"][0][0].should eq("must be a single value")
      config[:validate]["test"][0][1].is_a?(Proc).should eq(true)
    end

    it "should set optional with validation functions" do
      schema_file = File.join(@kvdb_path, "schema")
      File.open(schema_file, "w+") { |f| f.puts %q{
            nodes "host/*" do
                optional "test" => [:single_value]
            end
} }
      kv = KV.new(:path => @kvdb_path)
      config = KV::Audit::Config.new(kv).for("host/foo")
      config[:optional].should eq(["test"])
      config[:validate].keys.should eq(["test"])
      config[:validate]["test"].length.should eq(1)
      config[:validate]["test"][0].length.should eq(2)
      config[:validate]["test"][0][0].should eq("must be a single value")
      config[:validate]["test"][0][1].is_a?(Proc).should eq(true)
    end
  end # describe #initialize

  describe '#validate' do
    it "should set a validation Proc" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit::Config.new(kv)
      v = Proc.new { |value, node, kvdb| false }
      audit.validate("test", "testing descr", &v)

      config = audit.for("host/foo")
      config[:validate].should eq({"test" => [["testing descr", v]]})
    end
  end # describe #validate

  describe '#for' do
    it "should combine multiple validation Procs" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit::Config.new(kv)
      v1 = Proc.new { |value, node, kvdb| false }
      v2 = Proc.new { |value, node, kvdb| true }
      audit.validate("test", "t1", &v1)
      audit.validate("test", "t2", &v2)

      config = audit.for("host/foo")
      config[:validate].should eq({"test" => [["t1", v1], ["t2", v2]]})
    end

    it "should filter based on node name when combining" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit::Config.new(kv)
      v1 = Proc.new { |value, node, kvdb| false }
      v2 = Proc.new { |value, node, kvdb| true }
      audit.nodes("host/.*") do
        audit.validate("test", "t1", &v1)
      end
      audit.validate("test", "t2", &v2)

      config = audit.for("host/foo")
      config[:validate].keys.should eq(["test"])
      config[:validate]["test"].sort.should eq([["t1", v1], ["t2", v2]])

      config = audit.for("baz/foo")
      config[:validate].keys.should eq(["test"])
      config[:validate]["test"].sort.should eq([["t2", v2]])
    end
  end # describe #for
end # describe KV::Audit::Config
