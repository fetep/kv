class KV
  class Node
    class Attrs
      public
      def initialize
        @attrs = {}
      end # def initialize

      public
      def add(key, value)
        if ! value.is_a?(String)
          raise KV::Error, "value elements must be a String"
        end

        if ! KV::Util.key_valid?(key)
          raise KV::Error, "invalid key"
        end

        @attrs[key] ||= []
        @attrs[key] << value
      end # def add

      public
      def set(key, value)
        value = [value] unless value.is_a?(Array)
        value.each do |v|
          if ! v.is_a?(String)
            raise KV::Error, "value elements must be a String"
          end
        end

        if ! KV::Util.key_valid?(key)
          raise KV::Error, "invalid key"
        end

        @attrs[key] = value
      end

      public
      def [](key);
        v = @attrs[key]
        return v if v.nil?
        return v.length == 1 ? v.first : v
      end

      public
      def to_hash; @attrs; end

      public
      def clear
        @attrs = {}
      end

      public
      def each(&block)
        @attrs.each do |key, values|
          values.each do |value|
            yield(key, value)
          end
        end
      end # def each
    end # class Attrs
  end # class Node
end # class KV
