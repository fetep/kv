class KV
  module Util
    public
    def self.key_valid?(key)
      if key.index(':') || key.index('#') || key.index("'") ||
        key.index('"') || key.index(' ')
        return false
      end

      return true
    end # def self.key_valid?
  end # module Util
end # class KV
