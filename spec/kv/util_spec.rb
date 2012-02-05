require "rspec/autorun"
require "spec_helper"
require "kv/util"

describe KV::Util do
  describe '.key_valid?' do
    it "should return true on valid keys" do
      valid_keys = ["foo", "test.bar", "123.baz.bar"]
      valid_keys.each do |k|
        KV::Util.key_valid?(k).should eq(true)
      end
    end

    it "should return false on keys containing spaces" do
      KV::Util.key_valid?(" foo").should eq(false)
      KV::Util.key_valid?("foo ").should eq(false)
      KV::Util.key_valid?("fo o").should eq(false)
    end

    it "should return false on keys containing colons" do
      KV::Util.key_valid?(":foo").should eq(false)
    end

    it "should return false on keys containing double quotes" do
      KV::Util.key_valid?("foo\"bar").should eq(false)
    end

    it "should return false on keys containing single quotes" do
      KV::Util.key_valid?("foo'bar").should eq(false)
    end

    it "should return false on keys containing hashmarks" do
      KV::Util.key_valid?("foo#bar").should eq(false)
    end
  end

  describe '.parse_data' do
    it "should handle values with colons" do
      attrs = Hash.new { |h, k| h[k] = Array.new }
      KV::Util.parse_data("key1: value: foo\n") do |k, v|
        attrs[k] << v
      end

      expected = { "key1" => ["value: foo"] }
      attrs.should eq(expected)
    end

    it "should skip comments" do
      attrs = Hash.new { |h, k| h[k] = Array.new }
      data = ["key1: value1", "#comment: foo", "key2: value2"]
      KV::Util.parse_data(data.join("\n")) do |k, v|
        attrs[k] << v
      end

      expected = { "key1" => ["value1"], "key2" => ["value2"] }
      attrs.should eq(expected)
    end

    it "should skip blank lines" do
      attrs = Hash.new { |h, k| h[k] = Array.new }
      data = ["key1: value1", "", "key2: value2"]
      KV::Util.parse_data(data.join("\n")) do |k, v|
        attrs[k] << v
      end

      expected = { "key1" => ["value1"], "key2" => ["value2"] }
      attrs.should eq(expected)
    end

    it "should call block multiple times with same key name and different values" do
      attrs = Hash.new { |h, k| h[k] = Array.new }
      data = ["key1: value1", "key1: value2", "key2: value2"]
      KV::Util.parse_data(data.join("\n")) do |k, v|
        attrs[k] << v
      end

      expected = { "key1" => ["value1", "value2"], "key2" => ["value2"] }
      attrs.should eq(expected)
    end
  end

  describe '.expand_key_path' do
    it "should parse a full keypath with index" do
      node, key, index = KV::Util.expand_key_path("test/1#key1.key2#0")
      node.should eq("test/1")
      key.should eq("key1.key2")
      index.should eq(0)
    end

    it "should ignore an invalid keypath index" do
      node, key, index = KV::Util.expand_key_path("test/1#key1.key2#m")
      node.should eq("test/1")
      key.should eq("key1.key2")
      index.should eq(nil)

      node, key, index = KV::Util.expand_key_path("test/1#key1.key2#")
      node.should eq("test/1")
      key.should eq("key1.key2")
      index.should eq(nil)
    end

    it "should handle a keypath with a host and key, no index" do
      node, key, index = KV::Util.expand_key_path("test/1#key1.key2")
      node.should eq("test/1")
      key.should eq("key1.key2")
      index.should eq(nil)
    end

    it "should handle a keypath with a host no key or index" do
      node, key, index = KV::Util.expand_key_path("test/1")
      node.should eq("test/1")
      key.should eq(nil)
      index.should eq(nil)
    end

    it "should bail on an empty node name" do
      expect { KV::Util.expand_key_path("#key") }.should \
              raise_error(KV::Error, "invalid key path, cannot be empty")
      expect { KV::Util.expand_key_path("#key#0") }.should \
              raise_error(KV::Error, "invalid key path, cannot be empty")
    end

    it "should bail on invalid values" do
      expect { KV::Util.expand_key_path("") }.should \
              raise_error(KV::Error, "invalid key path, cannot be empty")
      expect { KV::Util.expand_key_path(nil) }.should \
              raise_error(KV::Error, "invalid key path type NilClass")
      expect { KV::Util.expand_key_path(:x) }.should \
              raise_error(KV::Error, "invalid key path type Symbol")
      expect { KV::Util.expand_key_path(Array.new) }.should \
              raise_error(KV::Error, "invalid key path type Array")
    end
  end
end # describe KV::Node
