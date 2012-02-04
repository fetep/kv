class KV; class Node
  attr_reader :attrs

  public
  def initialize(name, path)
    @name, @path = name, path
    @attrs = {}
    load_attrs(path)
  end # def initialize

  public
  def [](key)
    return @attrs[key]
  end

  private
  def load_attrs(path)
    new_attrs = {}
    File.open(path).each do |line|
      if line == '' or line[0..0] == '#'
        next
      end

      key, value = line.split(':')
      new_attrs[key.strip] = value.strip
    end
    @attrs = new_attrs
  rescue Errno::ENOENT
    # we have no attributes if there is no backing file to load
    @attrs = {}
  rescue
    raise KV::Error.new("node #{@name} failed to load from #{path}: #{$!}")
  end # def load_attrs
end; end # class KV::Node
