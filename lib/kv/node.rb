require "fileutils"
require "kv/node/attrs"
require "kv/util"

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
      load_data
    end # def initialize

    public
    def [](key); @attrs[key]; end

    public
    def add(key, value); @attrs.add(key, value); end

    public
    def set(key, value); @attrs.set(key, value); end

    public
    def save
      write_data
    end

    public
    def reload
      if changed?
        load_data
      end
    end # def reload

    public
    def changed?
      stat = File.stat(@path) rescue nil
      cur_mtime = stat ? stat.mtime : 0
      return cur_mtime != @mtime
    end # def changed?

    private
    def load_data
      new_attrs = KV::Node::Attrs.new
      File.open(@path) do |file|
        @mtime = file.stat.mtime

        KV::Util.parse_data(file.read) do |key, value|
          new_attrs.add(key, value)
        end
      end # File.open
      @attrs = new_attrs
    rescue Errno::ENOENT
      @attrs.clear
      @mtime = 0
    rescue
      raise KV::Error.new("node #{@name} failed to load from #{path}: #{$!}")
    end # def load_data

    private
    def write_data
      dest_dir = File.dirname(@path)
      if ! File.exists?(dest_dir)
        FileUtils.mkdir_p(dest_dir)
      end
      File.open(@path, "w+") do |file|
        @attrs.each do |k, v|
          file.puts "#{k}: #{v}"
        end
      end
    end # def write_data
  end # class Node
end # class KV
