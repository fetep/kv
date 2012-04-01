require "rubygems"
require "ferret"
require "json"

class KVD
  class Indexer
    attr_reader :index
    attr_reader :kv

    KVDB_NODE = "__kvdb_node"

    public
    def initialize(kv)
      @kv = kv
      @index = Ferret::Index::Index.new(:key => KVDB_NODE)

      initial_index
    end

    public
    def initial_index
      kv.nodes.each do |node_name|
        node = kv.node(node_name)
        doc = node.attrs.to_hash
        doc[KVDB_NODE] = node_name
        @index << doc
      end
    end # def initialize
  end # class Indexer
end # class KVD
