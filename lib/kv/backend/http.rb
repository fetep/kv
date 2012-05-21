require "kv/exception"
require "net/http"

class KV
  class Backend
    class HTTP
      public
      def initialize(opts)
        if opts[:path].nil?
          raise KV::Error, "no :path specified"
        end

        if opts[:path][0..6] != "http://"
          raise KV::Error, "unknown path type, not http://"
        end

        @uri = URI.parse(opts[:path])
        @http = Net::HTTP.new(@uri.host, @uri.port)
      end # def initialize

      public
      def node_path(node_name)
        raise KV::Error, NOT_IMPL
      end # def node_path

      public
      def node(node_name, skip_cache=false)
        n = KV::Node.new(node_name)
      end # def node

      public
      def node?(node_name)
        raise KV::Error, NOT_IMPL
      end # def node?

      public
      def nodes
        res = get("/search?q=*")
        JSON.parse(res)
      end # def nodes

      public
      def expand(key_path, verbose = false, raise_on_bad_node_name = true)
        raise KV::Error, NOT_IMPL
      end # def expand

      private
      def get(path)
        res = @http.get(path)
        if res.code != "200"
          raise KV::Error, "#{URI.join(@uri.to_s, path)} returned #{res.code}"
        end

        return res.body
      end
    end # class Base
  end # class Backend
end # class KV
