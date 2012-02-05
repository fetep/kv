require "kv/node/attrs"

class KV
  class Node
    attr_reader :attrs
    attr_reader :mtime
    attr_reader :name
    attr_reader :path

    public
    def initialize(name, path)
      @name, @path = name, path
      @mtime = 0
      @attrs = KV::Node::Attrs.new
      load_attrs
    end # def initialize

    public
    def [](key); @attrs[key]; end

    public
    def add(key, value); @attrs.add(key, value); end

    public
    def set(key, value); @attrs.set(key, value); end

    public
    def save
      write_attrs
    end

    public
    def reload
      if changed?
        load_attrs
      end
    end # def reload

    public
    def changed?
      stat = File.stat(@path) rescue nil
      cur_mtime = stat ? stat.mtime : 0
      return cur_mtime != @mtime
    end # def changed?

    private
    def load_attrs
      new_attrs = KV::Node::Attrs.new
      File.open(@path) do |file|
        @mtime = file.stat.mtime
        file.each do |line|
          line.chomp!
          if line == '' or line[0..0] == '#'
            next
          end

          key, value = line.split(':', 2)
          new_attrs.add(key.strip, value.strip)
        end # file.each
      end # File.open
      @attrs = new_attrs
    rescue Errno::ENOENT
      @attrs.clear
      @mtime = 0
    rescue
      raise KV::Error.new("node #{@name} failed to load from #{path}: #{$!}")
    end # def load_attrs

    private
    def write_attrs
      File.open(@path, "w+") do |file|
        @attrs.each do |k, v|
          file.puts "#{k}: #{v}"
        end
      end
    end # def write_attrs
  end # class Node
end # class KV
