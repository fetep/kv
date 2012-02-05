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
    def self.parse_data(data, &block)
      data.split("\n").each do |line|
        line.chomp!
        if line == '' or line[0..0] == '#'
          next
        end

        key, value = line.split(':', 2)
        yield(key.strip, value.strip)
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
        raise KV::Error, "invalid key path, cannot be empty"
      end

      return node, key, index
    end # def self.expand_key_path
  end # module Util
end # class KV
