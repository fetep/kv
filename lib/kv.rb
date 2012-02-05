require "rubygems"
require "fileutils"
require "json"
require "kv/exception"
require "uuidtools"

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

    load_metadata
  end # def initialize


  private
  def load_metadata
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
  end # def load_metadata

  private
  def write_metadata
    File.open(@kvdb_metadata_path, "w+") { |f| f.puts @kvdb_metadata.to_json }
  end # def write_metadata

  public
  def node_path(node_name)
    if @kvdb_metadata["mapping"][node_name]
      return @kvdb_metadata["mapping"][node_name]
    end

    # get a UUID, build a path
    uuid = UUIDTools::UUID.sha1_create(UUIDTools::UUID_OID_NAMESPACE,
                                       node_name).to_s
    path = File.join(uuid[0..0],
                     uuid[1..1],
                     uuid[2..2],
                     uuid)
    @kvdb_metadata["mapping"][node_name] = path

    # re-write metadata
    write_metadata

    return path
  end # def node_path

  public
  def node(node_name)
    return KV::Node.new(node_name, node_path(node_name))
  end
end # class KV
