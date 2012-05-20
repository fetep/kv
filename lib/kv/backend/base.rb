require "kv/exception"

class KV
  class Backend
    class Base
      NOT_IMPL = "command not supported by backend #{self.class}"

      public
      def kvdb_path
        raise KV::Error, NOT_IMPL
      end

      public
      def node_path(node_name)
        raise KV::Error, NOT_IMPL
      end

      public
      def node(node_name, skip_cache=false)
        raise KV::Error, NOT_IMPL
      end

      public
      def node?(node_name)
        raise KV::Error, NOT_IMPL
      end

      public
      def nodes
        raise KV::Error, NOT_IMPL
      end # def nodes

      public
      def expand(key_path, verbose = false, raise_on_bad_node_name = true)
        raise KV::Error, NOT_IMPL
      end # def expand

      public
      def delete(node_name)
        raise KV::Error, NOT_IMPL
      end # def delete
    end # class Base
  end # class Backend
end # class KV
