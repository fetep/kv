require "rubygems"
require "ferret"
require "json"

class KVD
  class Indexer
    attr_reader :index
    attr_reader :kv

    public
    def initialize(kv)
      @kv = kv
      @index = Ferret::Index::Index.new

      initial_index
    end

    public
    def initial_index
      kv.nodes.each do |node_name|
        node = kv.node(node_name)
        doc = node.attrs.to_hash
        doc[:id] = node_name
        @index << doc
      end
    end # def initialize
  end # class Indexer
end # class KVD
