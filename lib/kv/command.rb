require "rubygems"
require "kv"
require "kv/util"
require "trollop"

class KV
  class Command
    VALID_COMMANDS = ["import", "init", "list", "nodepath", "print", "set"]

    public
    def initialize(kvdb_path)
      @kvdb_path = kvdb_path
    end # def initialize

    public
    def run(cmd, args=[])
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
    def nodepath(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] nodepath <node>"
      end

      if args.length != 1
        raise KV::Error, "kv nodepath only takes one node argument"
      end

      node_name = args.shift

      if ! @kv.node?(node_name)
        raise KV::Error, "#{node_name} does not exist"
      end
      puts @kv.node(node_name).path
    end # def nodepath

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

    public
    def import(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] import <node> [<datafile>]" +
               "\n\n  reads from stdin if no datafile is provided"
               "\n\ndata should be of format 'key: value'"
      end

      node_name = args.shift
      datafile = args.shift

      if node_name.nil?
        raise KV::Error, "must specify a node name"
      end

      if args.length > 0
        raise KV::Error, "too many arguments"
      end

      if @kv.node?(node_name)
        raise KV::Error, "#{node_name} already exists"
      end

      set(["-c", node_name, datafile])
    end

    public
    def set(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] set [-c] <node> [<datafile>]" +
               "\n\n  reads from stdin if no datafile is provided"
               "\n\ndata should be of format 'key: value'"

        opt :create, :description => "allow creation of new nodes",
            :default => false
      end

      node_name = args.shift
      datafile = args.shift

      if node_name.nil?
        raise KV::Error, "must specify a node name"
      end

      if args.length > 0
        raise KV::Error, "too many arguments"
      end

      if ! @kv.node?(node_name) and ! opts[:create]
        raise KV::Error, "node #{node_name} does not exist, and -c not given"
      end

      if datafile and ! File.exists?(datafile)
        raise KV::Error, "#{datafile}: data file does not exist"
      end

      node = @kv.node(node_name)
      KV::Util.parse_data(datafile ? File.read(datafile) : STDIN.read) do |k, v|
        node.add(k, v)
      end
      node.save
    end

    private
    def kv_init
      @kv ||= KV.new(:path => @kvdb_path)
    end # def kv_init
  end # class Command
end # class KV
