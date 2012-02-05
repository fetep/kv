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
end # describe KV::Node
