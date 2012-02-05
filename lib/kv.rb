require "fileutils"
require "json"
require "kv/exception"

class KV
  public
  def self.create_kvdb(kvdb_path)
    kvdb_metadata_path = File.join(kvdb_path, ".kvdb")
    kvdb_metadata = {
      "version" => "1",
      "mapping" => {},
    }

    if File.exists?(kvdb_path)
      raise KV::Error.new("#{kvdb_path} exists, cannot create a kvdb there")
    end

    FileUtils.mkdir_p(kvdb_path)
    File.open(kvdb_metadata_path, "w+") do |f|
      f.puts kvdb_metadata.to_json
    end
  end # def self.create_kvdb

  public
  def initialize(opts)
    @opts = {
      :path => nil,
    }.merge(opts)

    if @opts[:path].nil?
      raise KV::Error.new("missing :path argument to constructor")
    end

    @kvdb_metadata_path = File.join(@opts[:path], ".kvdb")
    if !File.exists?(@kvdb_metadata_path)
      raise KV::Error.new("can't see #{@kvdb_metadata_path}")
    end

    begin
      @kvdb_metadata = JSON.parse(File.read(@kvdb_metadata_path))
    rescue
      raise KV::Error.new("error parsing #{@kvdb_metadata_path}: #{$!}")
    end

    if ! @kvdb_metadata["mapping"].is_a?(Hash)
      raise KV::Error.new("corrupt metadata, mapping is not a hash")
    end

    if ! @kvdb_metadata.member?("version")
      raise KV::Error.new("corrupt metadata, version is missing")
    end

    # TODO(petef): some day handle the ability to have multiple versions.
    if @kvdb_metadata["version"] != "1"
      raise KV::Error.new("unknown metadata version #{@kvdb_metadata["version"].inspect}")
    end
  end # def initialize

  public
  def lookup_node_path(node)
  end # def lookup_node_path

  public
  def lookup_node(node)
    File.open(lookup_node_path(node)) do |f|
    end
  end # def lookup_node
end # class KV
