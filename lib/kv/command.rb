require "rubygems"
require "kv"
require "kv/util"
require "tempfile"
require "trollop"

class KV
  class Command
    VALID_COMMANDS = ["import", "init", "list", "nodepath", "print", "set",
                      "cp", "edit", "rm", "find"]

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
        raise KV::Error, "init takes no arguments"
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
        raise KV::Error, "list only takes one filter argument"
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
        raise KV::Error, "nodepath takes one argument"
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

        opt :verbose, "verbose, always show keypath in output"
      end

      if args.length != 1
        raise KV::Error, "print takes one argument"
      end

      key_path = args.first

      puts @kv.expand(key_path, opts[:verbose]).join("\n")
    end

    public
    def find(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] find <lucene expression>"
      end

      if args.length == 0
        raise KV::Error, "find needs a lucene expression"
      end

      #puts @kv.find(args.join(" AND "))
      puts @kv.find(args.join(" "))
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
        banner "Usage: kv [-d dir] set [-c] [-a] <node> [<datafile>]" \
               "\n       kv [-d dir] set [-c] [-a] -f [<datafile>]" \
               "\n\n  reads from stdin if no datafile is provided" \
               "\n\ndata should be of format 'key: value'"

        opt :create, "allow creation of new nodes",
            :default => false
        opt :append,
            "append to existing values (default is overwrite)",
            :default => false
        opt :full,
            "read full nodepaths (node#key) from datafile",
            :default => false
      end


      if !opts[:full]
        node_name = args.shift

        if node_name.nil?
          raise KV::Error, "must specify a node name"
        end

        if ! @kv.node?(node_name) and ! opts[:create]
          raise KV::Error, "node #{node_name} does not exist, and -c not given"
        end
      end

      datafile = args.shift

      if args.length > 0
        raise KV::Error, "too many arguments"
      end

      if datafile and ! File.exists?(datafile)
        raise KV::Error, "#{datafile}: data file does not exist"
      end

      if opts[:full]
        node_cache = Hash.new { |h, k| h[k] = @kv.node(k) }
        adds = Hash.new { |h, k| h[k] = [] }
        KV::Util.parse_data(datafile ? File.read(datafile) : STDIN.read, true) do |n, k, v|
          if ! @kv.node?(n) and ! opts[:create]
            raise KV::Error, "node #{n} does not exist, and -c not given"
          end
          node_cache[n].delete(k) unless opts[:append]
          adds[n] << [k, v]
        end

        adds.each do |n, add|
          add.each do |k, v|
            node_cache[n].add(k, v)
          end
        end

        node_cache.values.each { |n| n.save }
      else
        node = @kv.node(node_name)
        add = []

        KV::Util.parse_data(datafile ? File.read(datafile) : STDIN.read) do |k, v|
          node.delete(k) unless opts[:append]
          add << [k, v]
        end

        add.each do |k, v|
          node.add(k, v)
        end

        node.save
      end
    end

    public
    def cp(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] cp <node> <new_node>"
      end

      if args.length != 2
        raise KV::Error, "cp takes two arguments"
      end

      src_node_name = args.shift
      dst_node_name = args.shift

      if ! @kv.node?(src_node_name)
        raise KV::Error, "node #{src_node_name} does not exist"
      end
      if @kv.node?(dst_node_name)
        raise KV::Error, "node #{dst_node_name} already exists"
      end

      src_node = @kv.node(src_node_name)
      dst_node = @kv.node(dst_node_name)
      src_node.attrs.to_hash.each do |key, values|
        values.each do |value|
          dst_node.add(key, value)
        end
      end
      dst_node.save
    end

    public
    def rm(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] rm <node>"
      end

      if args.length != 1
        raise KV::Error, "rm takes one argument"
      end

      node_name = args.shift

      if ! @kv.node?(node_name)
        raise KV::Error, "node #{node_name} does not exist"
      end

      @kv.delete(node_name)
    end

    public
    def edit(args)
      kv_init

      opts = Trollop::options(args) do
        banner "Usage: kv [-d dir] edit [-c] <node>"

        opt :create, "allow creation of new nodes",
            :default => false
      end

      if args.length != 1
        raise KV::Error, "edit takes one node name"
      end

      node_name = args.shift
      if not opts[:create] and not @kv.node?(node_name)
        raise KV::Error, "node #{node_name} does not exist (-c to create)"
      end
      node = @kv.node(node_name)
      node_path = node.path

      tmp_path = Tempfile.new("kv")
      tmp_path.puts "# #{node_name}"
      node.attrs.each do |attr, value|
        tmp_path.puts "#{attr}: #{value}"
      end
      tmp_path.flush

      editor = ENV["EDITOR"] || "vi"
      system("sh", "-c", [editor, tmp_path.path].join(" "))
      if $?.exitstatus != 0
        raise KV::Error, "aborting edit, editor exited #{$?.exitstatus}"
      end

      # set new attributes
      set([node_name, tmp_path.path])

      # handle attribute deletion
      keys = {}
      KV::Util.parse_data(File.read(tmp_path.path)) { |k, v| keys[k] = true }
      node = @kv.node(node_name)
      changed = false
      node.attrs.to_hash.keys.each do |k|
        next if keys.member?(k)
        node.delete(k)
        changed = true
      end
      node.save if changed

      tmp_path.unlink
      tmp_path.close
    end

    private
    def kv_init
      @kv ||= KV.new(:path => @kvdb_path)
    end # def kv_init
  end # class Command
end # class KV
