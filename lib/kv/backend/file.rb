require "rubygems"
require "fileutils"
require "json"
require "kv/backend/base"
require "kv/exception"
require "kv/node"
require "kv/util"
require "uuidtools"

class KV
  class Backend
    class File < Base
      public
      def initialize(opts)
        @opts = {
          :path => nil,
        }.merge(opts)

        if @opts[:path].nil?
          raise KV::Error.new("missing :path argument to constructor")
        end

        @kvdb_metadata_path = ::File.join(@opts[:path], ".kvdb")
        if !::File.exists?(@kvdb_metadata_path)
          raise KV::Error.new("can't see #{@kvdb_metadata_path}")
        end

        @nodes = {}

        refresh
      end # def initialize


      public
      def refresh
        @nodes = {}

        begin
          @kvdb_metadata = JSON.parse(::File.read(@kvdb_metadata_path))
        rescue
          raise KV::Error.new("error parsing #{@kvdb_metadata_path}: #{$!}")
        end

        if ! @kvdb_metadata["mapping"].is_a?(Hash)
          raise KV::Error.new("corrupt metadata, mapping is not a hash")
        end

        if ! @kvdb_metadata.member?("version")
          raise KV::Error.new("corrupt metadata, version is missing")
        end

        # TODO(petef): some day handle the ability to have multiple versions.
        if @kvdb_metadata["version"] != "1"
          raise KV::Error.new("unknown metadata version #{@kvdb_metadata["version"].inspect}")
        end
      end # def load_metadata

      private
      def write_metadata
        tmp_path = Tempfile.new("kv")
        h = KV::Util.convert_hash_to_ordered_hash_and_sort(@kvdb_metadata, true)
        tmp_path.puts JSON.pretty_generate(h)
        tmp_path.close
        ::File.rename(tmp_path.path, @kvdb_metadata_path)
      end # def write_metadata

      public
      def kvdb_path
        return @opts[:path]
      end

      public
      def node_path(node_name)
        if ! node_name.is_a?(String)
          raise "node_path takes a String, not: #{node_name.inspect}"
        end
        if @kvdb_metadata["mapping"][node_name]
          return ::File.join(@opts[:path], @kvdb_metadata["mapping"][node_name])
        end

        # get a UUID, build a path
        uuid = UUIDTools::UUID.sha1_create(UUIDTools::UUID_OID_NAMESPACE,
                                          node_name).to_s
        path = ::File.join(uuid[0..0],
                           uuid[1..1],
                           uuid[2..2],
                           uuid)
        @kvdb_metadata["mapping"][node_name] = path

        # re-write metadata
        write_metadata

        return ::File.join(@opts[:path], path)
      end # def node_path

      public
      def node(node_name, skip_cache=false)
        if skip_cache
          return KV::Node.new(node_name, node_path(node_name))
        end

        @nodes[node_name] ||= KV::Node.new(node_name, node_path(node_name))
        return @nodes[node_name]
      end

      public
      def node?(node_name)
        return @kvdb_metadata["mapping"].keys.member?(node_name)
      end

      public
      def nodes
        return @kvdb_metadata["mapping"].keys.sort
      end # def nodes

      public
      def expand(key_path, verbose = false, raise_on_bad_node_name = true)
        res = []
        # key_path must be a full key_path or just a node name
        node_name, key, index = KV::Util.expand_key_path(key_path)

        if ! node?(node_name)
          if raise_on_bad_node_name
            raise KV::Error, "node #{node_name} does not exist"
          else
            return res
          end
        end

        node = self.node(node_name)
        if key.nil?
          node.attrs.to_hash.each do |key, values|
            res.push(*expand_values(node, key, values, true))
          end
        elsif node[key]
          res.push(*expand_values(node, key, node[key], verbose))
        end

        return res.sort
      end # def expand

      public
      def delete(node_name)
        if ! node?(node_name)
          raise KV::Error, "node #{node_name} does not exist"
        end

        n = node(node_name)
        ::File.unlink(n.path)
        @nodes.delete(node_name)
        @kvdb_metadata["mapping"].delete(node_name)
        write_metadata
      end

      private
      def expand_values(node, key, values, verbose)
        res = []
        values = [values] unless values.is_a?(Array)

        index = values.length > 1 ? 0 : nil

        values.each do |value|
          if verbose
            index_suffix = index ? "##{index}" : ""
            res << "#{node.name}##{key}#{index_suffix}: #{value}"
            index += 1 if index
          else
            res << value
          end
        end

        return res
      end # def expand_values
    end # class File
  end # class Backend
end # class KV
