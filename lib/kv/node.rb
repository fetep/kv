class KV; class Node
  attr_reader :attrs
  attr_reader :mtime
  attr_reader :name
  attr_reader :path

  public
  def initialize(name, path)
    @name, @path = name, path
    @mtime = 0
    @attrs = {}
    load_attrs
  end # def initialize

  public
  def [](key)
    return @attrs[key]
  end

  public
  def reload
    if changed?
      load_attrs
    end
  end

  public
  def changed?
    stat = File.stat(@path) rescue nil
    cur_mtime = stat ? stat.mtime : 0
    return cur_mtime != @mtime
  end

  private
  def load_attrs
    new_attrs = {}
    File.open(@path) do |file|
      @mtime = file.stat.mtime
      file.each do |line|
        if line == '' or line[0..0] == '#'
          next
        end

        key, value = line.split(':', 2)
        new_attrs[key.strip] = value.strip
      end # file.each
    end # File.open
    @attrs = new_attrs
  rescue Errno::ENOENT
    @attrs = {}
    @mtime = 0
  rescue
    raise KV::Error.new("node #{@name} failed to load from #{path}: #{$!}")
  end # def load_attrs
end; end # class KV::Node
