require "rubygems"
require "active_support" # for OrderedHash

class KV
  module Util
    public
    def self.key_valid?(key)
      return false unless key.is_a?(String)

      if key.index(':') || key.index('#') || key.index("'") ||
        key.index('"') || key.index(' ')
        return false
      end

      return true
    end # def self.key_valid?

    public
    def self.value_valid?(value)
      return false unless value.is_a?(String)
      return !value.empty?
    end

    public
    def self.parse_data(data, full_keypath=false, &block)
      data.split("\n").each do |line|
        line.chomp!
        if line == '' or line[0..0] == '#'
          next
        end

        key, value = line.split(':', 2)
        if full_keypath
          node, key, index = self.expand_key_path(key)
          yield(node, key.strip, value.strip)
        else
          yield(key.strip, value.strip)
        end
      end
    end # def self.parse_data

    public
    def self.expand_key_path(key_path)
      if ! key_path.is_a?(String)
        raise KV::Error, "invalid key path type #{key_path.class}"
      end
      node, key, index = key_path.split('#', 3)
      if index
        index = Integer(index) rescue nil
      end

      if node.nil? or node.empty?
        raise KV::Error, "#{key_path}: invalid key path, cannot be empty"
      end

      return node, key, index
    end # def self.expand_key_path

    public
    def self.convert_hash_to_ordered_hash_and_sort(object, deep = false)
      # from https://gist.github.com/1083930
      if object.is_a?(Hash)
        res = ActiveSupport::OrderedHash.new
        object.each do |k, v|
          res[k] = deep ? convert_hash_to_ordered_hash_and_sort(v, deep) : v
        end
        return res.class[res.sort {|a, b| a[0].to_s <=> b[0].to_s } ]
      elsif deep && object.is_a?(Array)
        array = Array.new
        object.each_with_index do |v, i|
          array[i] = convert_hash_to_ordered_hash_and_sort(v, deep)
        end
        return array
      else
        return object
      end
    end # def self.convert_hash_to_ordered_hash_and_sort
  end # module Util
end # class KV
