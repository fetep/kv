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
  end # module Util
end # class KV
