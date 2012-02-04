class KV; class Util
  public
  def self.key_valid?(key)
    if key.index(':') || key.index('#') || key.index("'") ||
       key.index('"') || key.index(' ')
      return false
    end

    return true
  end # def initialize
end; end # class KV::Util
