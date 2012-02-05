Gem::Specification.new do |spec|
  files = []
  paths = %w{lib spec}
  paths.each do |path|
    if File.file?(path)
      files << path
    else
      files += Dir["#{path}/**/*"]
    end
  end

  spec.name = "kv"
  spec.version = "0.0.1"
  spec.summary = "kv - simple file-backed key-value store"
  spec.description = ""
  spec.license = "MPL 2.0"

  spec.add_dependency "json"
  spec.add_dependency "thor"
  spec.add_dependency "uuidtools"

  # testing-related
  spec.add_dependency "mkdtemp"
  spec.add_dependency "rspec"

  spec.files = files
  spec.require_paths << "lib"
  spec.bindir = "bin"
  spec.executables << "kv"

  spec.authors = ["Pete Fritchman"]
  spec.email = ["petef@databits.net"]
  spec.homepage = "https://github.com/fetep/kv"
end
