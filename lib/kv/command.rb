require "rubygems"
require "kv"
require "kv/util"
require "thor"

class KV
  class Command < Thor
    desc "init", "initialize new kvdb directory"
    def init
      KV.create_kvdb($kvdb_path)
    end

    desc "list [REGEXP]", "list nodes, optionally filtering by regexp"
    def list(regexp=nil)
      kv_init

      regexp = Regexp.new(regexp) if regexp
      @kv.nodes.each do |node|
        if regexp
          next unless node.match(regexp)
        end
        puts node
      end
    end # def node_list

    desc "nodepath NODE", "list path to data file for given node"
    def nodepath(node)
      kv_init

      if ! @kv.node?(node)
        raise KV::Error, "#{node} does not exist"
      end
      puts @kv.node(node).path
    end

    desc "import NODE [DATAFILE]", "import new node"
    def import(node, datafile=nil)
      kv_init

      if @kv.node?(node)
        raise KV::Error, "#{node} already exists"
      end

      if datafile && !File.exists?(datafile)
        raise KV::Error, "#{datafile}: data file does not exist"
      end

      n = @kv.node(node)
      KV::Util.parse_data(datafile ? File.read(datafile) : STDIN.read) do |k, v|
        n.add(k, v)
      end
      n.save
    end

    private
    def kv_init
      @kv = KV.new(:path => $kvdb_path)
    end
  end # class Command
end # class KV
