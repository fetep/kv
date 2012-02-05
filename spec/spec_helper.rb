require "rubygems"
require "fileutils"
require "mkdtemp"
require "tempfile"
require "rspec"

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
  new_stdout = Tempfile.new("test-stdout")
  new_stderr = Tempfile.new("test-stderr")
  $stdout, $stderr = new_stdout, new_stderr
  yield
  $stdout, $stderr = old_stdout, old_stderr
  new_stdout.flush
  new_stderr.flush
  stdout_output = File.read(new_stdout.path)
  stderr_output = File.read(new_stderr.path)
  new_stdout.close
  new_stderr.close
  return stdout_output, stderr_output
end
