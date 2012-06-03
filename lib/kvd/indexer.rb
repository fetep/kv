require "rubygems"
require "ferret"
require "json"
require "rb-inotify"

class KVD
  class Indexer
    attr_reader :index
    attr_reader :kv

    public
    def initialize(kv)
      @kv = kv
      field_infos = Ferret::Index::FieldInfos.new(
        :term_vector => :no,
        :index => :untokenized_omit_norms
      )
      @index = Ferret::Index::Index.new(
        :key => "_node",
        :field_infos => field_infos
      )

      @path_cache = {}

      initial_index
    end

    public
    def initial_index
      @kv.nodes.each do |node_name|
        update_node(node_name)
      end
    end # def initialize

    public
    def delete_node(node_name)
      existing = @index.scan("_node:#{node_name}")
      @index.delete(existing) if existing.length > 0
    end

    def update_node(node_name)
      delete_node(node_name)

      node = @kv.node(node_name, true) # skip cache
      doc = node.attrs.to_hash
      doc["_node"] = node_name
      @index << doc
    end

    def update_kvdb
      old_nodes = @kv.nodes
      @kv.refresh
      new_nodes = @kv.nodes

      # old nodes that no longer exist
      (old_nodes - new_nodes).each do |node_name|
        delete_node(node_name)
      end

      # new nodes
      (new_nodes - old_nodes).each do |node_name|
        update_node(node_name)
      end
    end

    def watch
      notifier = INotify::Notifier.new
      notifier.watch(kv.kvdb_path, :recursive, :modify, :move) do |event|
        if event.name == ""
          # skip
        elsif event.name == ".kvdb"
          update_kvdb
        else
          name = event.absolute_name
          if @path_cache[name].nil?
            @path_cache = {}
            @kv.nodes.each do |node_name|
              path = @kv.node_path(node_name)
              @path_cache[path] = node_name
            end
          end

          if @path_cache[name]
            update_node(@path_cache[name])
          else
            $stderr.puts "WARNING: unknown inotify path #{name.inspect}"
          end
        end
      end # inotify.watch
      notifier.run
    end # def watch
  end # class Indexer
end # class KVD
