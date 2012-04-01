require "rubygems"
require "fileutils"
require "json"
require "kv/backend/file"
require "kv/exception"
require "kv/node"
require "kv/util"
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
  def self.new(opts)
    opts = {
      :path => nil,
    }.merge(opts)

    if opts[:path].nil?
      raise KV::Error.new("missing :path argument to constructor")
    end

    return KV::Backend::File.new(opts)
  end # def initialize
end # class KV
