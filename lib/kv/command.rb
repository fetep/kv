require "rubygems"
require "kv"
require "kv/util"
require "trollop"

class KV
  class Command
    VALID_COMMANDS = ["import", "init", "list", "nodepath", "print"]

    public
    def initialize(kvdb_path)
      @kvdb_path = kvdb_path
    end # def initialize

    public
    def run(cmd, args)
      if ! VALID_COMMANDS.member?(cmd)
        raise KV::Error, "invalid subcommand #{cmd}"
      end

      send(cmd, args)
    end # def run

    public
    def init(args)
      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] init"
      end

      if args.length > 0
        raise KV::Error, :args, "init takes no arguments"
      end

      KV.create_kvdb(@kvdb_path)
    end # def init

    public
    def list(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] list [-p] [regexp]"
        opt :path, "Include data file path in output"
      end

      if args.length > 1
        raise KV::Error, "kv list only takes one filter argument"
      end

      regexp = Regexp.new(args.first) if args.length > 0
      @kv.nodes.each do |node|
        if regexp
          next unless node.match(regexp)
        end

        if opts[:path]
          puts "#{node} #{@kv.node_path(node)}"
        else
          puts node
        end
      end
    end # def list

    public
    def nodepath(*args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] nodepath <node>"
      end

      if args.length > 1
        raise KV::Error, "kv nodepath only takes one node argument"
      end

      node = args.shift

      if ! @kv.node?(node)
        raise KV::Error, "#{node} does not exist"
      end
      puts @kv.node(node).path
    end # def nodepath

    def import(*args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] import <node> [<datafile>]" +
               "\n\n  reads from stdin if no datafile is provided"
      end

      if args.length == 0
        raise KV::Error, "kv import takes at least one argument"
      end

      if args.length > 2
        raise KV::Error, "kv import takes at most two arguments"
      end

      node = args.shift
      datafile = args.shift

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

    public
    def print(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] print [-v] <keypath>"

        opt :verbose, :description => "verbose, always show keypath in output"
      end

      if args.length != 1
        raise KV::Error, "kv print takes exactly one argument"
      end

      key_path = args.first

      puts @kv.expand(key_path, opts[:verbose]).join("\n")
    end

    private
    def kv_init
      @kv ||= KV.new(:path => @kvdb_path)
    end # def kv_init
  end # class Command
end # class KV
