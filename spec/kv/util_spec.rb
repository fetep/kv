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
end # describe KV::Node
