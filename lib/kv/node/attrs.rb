class KV
  class Node
    class Attrs
      public
      def initialize
        @attrs = {}
      end # def initialize

      public
      def add(key, value)
        if ! KV::Util.value_valid?(value)
          raise KV::Error, "invalid value"
        end

        if ! KV::Util.key_valid?(key)
          raise KV::Error, "invalid key"
        end

        @attrs[key] ||= []
        @attrs[key] << value
      end # def add

      public
      def set(key, value, overwrite=true)
        value = [value] unless value.is_a?(Array)
        value.each do |v|
          if ! KV::Util.value_valid?(v)
            raise KV::Error, "invalid value"
          end
        end

        if ! KV::Util.key_valid?(key)
          raise KV::Error, "invalid key"
        end

        @attrs[key] = value
      end

      public
      def delete(key)
        @attrs.delete(key)
      end

      public
      def [](key);
        v = @attrs[key]
        return v if v.nil?
        return v.length == 1 ? v.first : v
      end

      public
      def []=(key, value);
        set(key, value)
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
