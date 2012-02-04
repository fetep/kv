require "rubygems"
require "fileutils"
require "mkdtemp"

require "kv"

RSpec.configure do |c|
  c.before(:each) do
    @tmp_dir = Dir.mkdtemp
    @kvdb_path = File.join(@tmp_dir, "kvdb")
    @kvdb_metadata_path = File.join(@kvdb_path, ".kvdb")
    KV.create_kvdb(@kvdb_path)
  end

  c.after(:each) do
    FileUtils.rm_rf(@tmp_dir)
  end
end
