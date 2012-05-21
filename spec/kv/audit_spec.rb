require "rspec/autorun"
require "spec_helper"
require "kv/audit"

describe KV::Audit do
  describe "#audit" do
    it "should run an audit on all nodes, with filtered validations" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit.new(kv)

      audit.config.required({"t1" => []})
      audit.config.nodes("test/.*") { audit.config.required({"t2" => []}) }

      n1 = kv.node("test1/foo")
      n1.attrs["t1"] = "test"
      n2 = kv.node("test/foo")
      n2.attrs["t1"] = "test"

      messages = audit.audit
      messages.should eq({"test/foo" => ["missing required key t2"]})
    end
  end # describe #audit

  describe "#audit_required" do
    it "should require keys be present" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit.new(kv)

      audit.config.required({"t1" => []})

      n1 = kv.node("test/foo")
      n1.attrs["t2"] = "test"

      messages = audit.audit
      messages.should eq({"test/foo" => ["missing required key t1"]})
    end

    it "should also add validations" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit.new(kv)

      audit.config.required({"t1" => [:single_value]})

      n1 = kv.node("test/foo")
      n1.attrs["t1"] = ["a", "b"]

      messages = audit.audit
      messages.should eq({"test/foo" => ["t1: [\"a\", \"b\"]: must be a single value"]})
    end

    it "should always pass with multi_value" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit.new(kv)

      audit.config.required({"t1" => [:multi_value]})

      n1 = kv.node("test/foo")
      n1.attrs["t1"] = ["a", "b"]

      messages = audit.audit
      messages.should eq({})

      n1 = kv.node("test/foo")
      n1.attrs["t1"] = "a"

      messages = audit.audit
      messages.should eq({})
    end

    it "should check references" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit.new(kv)

      audit.config.required({"t1" => [:reference]})

      n1 = kv.node("test/foo")
      n1.attrs["t1"] = "not-a-ref"
      messages = audit.audit
      messages.should eq({"test/foo" => ["t1: \"not-a-ref\": invalid reference"]})

      n1.attrs["t1"] = "%test/bar"
      messages = audit.audit
      messages.should eq({"test/foo" => ["t1: \"%test/bar\": invalid reference"]})

      n1.attrs["t1"] = "%test/foo"
      messages = audit.audit
      messages.should eq({})
    end

    it "should check references on multi-value keys" do
      kv = KV.new(:path => @kvdb_path)
      audit = KV::Audit.new(kv)

      audit.config.required({"t1" => [:reference]})

      v1 = kv.node("valid1")
      v1.attrs["t1"] = "%valid2"
      v2 = kv.node("valid2")
      v2.attrs["t1"] = "%valid1"
      n1 = kv.node("test/foo")
      n1.attrs["t1"] = ["%valid1", "invalid"]

      messages = audit.audit
      messages.should eq({"test/foo" => ["t1: [\"%valid1\", \"invalid\"]: invalid reference"]})

      n1.attrs["t1"] = ["%valid1", "%valid2"]

      messages = audit.audit
      messages.should eq({})
    end
  end # describe #audit_required

  describe "#audit_validations" do
    it "should run a custom violation" do
      #kv = KV.new(:path => @kvdb_path)
      #audit = KV::Audit.new(kv)

      #audit.config.required({"t1" => []})
      #audit.config.nodes("test/.*") { audit.config.required({"t2" => []}) }

      #n1 = kv.node("test1/foo")
      #n1.attrs["t1"] = "test"
      #n2 = kv.node("test/foo")
      #n2.attrs["t1"] = "test"

      #messages = audit.audit
      #messages.should eq({"test/foo" => ["missing required key t2"]})
    end
  end # describe #audit_validations
end # describe KV::Audit
