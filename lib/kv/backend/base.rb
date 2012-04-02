require "kv/exception"

class KV
  class Backend
    class Base
      NOT_IMPL = "command not supported by backend #{self.type}"

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
    end # class Base
  end # class Backend
end # class KV
