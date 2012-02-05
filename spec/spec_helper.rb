require "rubygems"
require "fileutils"
require "mkdtemp"
require "rspec"
require "stringio"

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
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

def wrap_output(&block)
  old_stdout, old_stderr = $stdout, $stderr
  new_stdout = StringIO.new
  new_stderr = StringIO.new
  $stdout, $stderr = new_stdout, new_stderr
  yield
  $stdout, $stderr = old_stdout, old_stderr
  new_stdout.seek(0)
  new_stderr.seek(0)
  return new_stdout.read, new_stderr.read
end
