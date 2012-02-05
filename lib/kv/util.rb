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
  end # module Util
end # class KV
