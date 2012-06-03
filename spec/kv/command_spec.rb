require "rspec/autorun"
require "spec_helper"
require "kv/command"

describe KV::Command do
  describe '#run' do
    it "should error on an unknown command" do
      expect { KV::Command.new($kvdb_path).run("foo") }.should \
        raise_error(KV::Error, "invalid subcommand foo")
    end
  end

  describe '#init' do
    it "should initialize a new kvdb" do
      new_kvdb_path = File.join(@tmp_dir, "kvdb2")
      KV::Command.new(new_kvdb_path).run("init")

      expect { KV.new(:path => new_kvdb_path) }.should_not \
        raise_error(KV::Error)
    end

    it "should error when passed any arguments" do
      expect { KV::Command.new($kvdb_path).init(["foo"]) }.should \
        raise_error(KV::Error, "init takes no arguments")
    end
  end

  describe '#list' do
    it "should list all nodes" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      expected = []
      3.times do |n|
        kv.node("test/#{n}")
        expected << "test/#{n}"
      end

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("list")
      end
      stdout.should eq(expected.join("\n") + "\n")
    end

    it "should filter based on a regexp" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      kv.node("test/1")
      kv.node("foo/1")

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("list", ["test/"])
      end
      stdout.should eq("test/1\n")
    end

    it "should print the full keypath with -v" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      expected = []
      n = kv.node("test/1")
      expected << "#{n.name} #{n.path}"
      n = kv.node("test/2")
      expected << "#{n.name} #{n.path}"

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("list", ["-p", "test/"])
      end
      stdout.should eq(expected.join("\n") + "\n")
    end

    it "should error when given too many arguments" do
      kv = KV.new(:path => @kvdb_path)
      expect { KV::Command.new(@kvdb_path).list(["foo", "bar"]) }.should \
        raise_error(KV::Error, "list only takes one filter argument")
    end
  end

  describe '#nodepath' do
    it "should error given a non-existant node" do
      $kvdb_path = @kvdb_path

      stdout, stderr = wrap_output do
        expect do
          KV::Command.new(@kvdb_path).run("nodepath", ["foo/bar"])
        end.should raise_error(KV::Error, "foo/bar does not exist")
      end
      stdout.should eq('')
    end

    it "should print the full path to a node" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      n = kv.node("test")
      n.save

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("nodepath", ["test"])
      end

      stdout.chomp.should eq(n.path)
    end

    it "should require exactly one argument" do
      expect { KV::Command.new(@kvdb_path).run("nodepath", []) }.should \
        raise_error(KV::Error, "nodepath takes one argument")

      expect { KV::Command.new(@kvdb_path).run("nodepath", ["a", "b"]) }.should \
        raise_error(KV::Error, "nodepath takes one argument")
    end
  end

  describe '#import' do
    it "should fail if the node already exists" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      n = kv.node("test")
      n.save

      stdout, stderr = wrap_output do
        expect do
          KV::Command.new(@kvdb_path).run("import", ["test", "/dev/null"])
        end.should raise_error(KV::Error, "test already exists")
      end
      stdout.should eq('')
    end

    it "should fail if the specified file does not exist" do
      $kvdb_path = @kvdb_path

      bad_path = File.join(@tmp_dir, "not", "here")
      stdout, stderr = wrap_output do
        expect do
          KV::Command.new(@kvdb_path).run("import", ["test", bad_path])
        end.should raise_error(KV::Error, "#{bad_path}: data file does not exist")
      end
      stdout.should eq('')
    end

    it "should fail with the wrong number of arguments" do
      expect { KV::Command.new(@kvdb_path).run("import", []) }.should \
        raise_error(KV::Error, "must specify a node name")

      expect { KV::Command.new(@kvdb_path).run("import", ["a", "b", "c"]) }.should \
        raise_error(KV::Error, "too many arguments")
    end
  end

  describe '#set' do
    it "should load data from a file" do
      $kvdb_path = @kvdb_path

      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "key1: value1"
        f.puts "key1: value2"
        f.puts "key2: value"
      end

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("set", ["-c", "test", data_file])
      end
      stdout.should eq('')

      kv = KV.new(:path => $kvdb_path)
      kv.node?("test").should eq(true)
      n = kv.node("test")
      n["key1"].should eq(["value1", "value2"])
      n["key2"].should eq("value")
    end

    it "should overwrite existing keys by default" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.add("key1", "value1")
      n.save

      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "key1: value2"
      end

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("set", ["test", data_file])
      end

      n = kv.node("test", true)
      n["key1"].should eq("value2")
    end

    it "should append to existing keys with -a" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test")
      n.add("key1", "value1")
      n.save

      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "key1: value2"
      end

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("set", ["-a", "test", data_file])
      end

      n = kv.node("test", true)
      n["key1"].should eq(["value1", "value2"])
    end

    it "should refuse to create a new node without -c" do
      kv = KV.new(:path => @kvdb_path)

      expect { KV::Command.new(@kvdb_path).run("set", ["test/1"]) }.should \
        raise_error(KV::Error, "node test/1 does not exist, and -c not given")
    end

    it "should create a new node with -c" do
      expect { KV::Command.new(@kvdb_path).run("set", ["-c", "test/1", "/dev/null"]) }.should_not \
        raise_error(KV::Error, "node test/1 does not exist, and -c not given")
    end

    it "should fail with the wrong number of arguments" do
      expect { KV::Command.new(@kvdb_path).run("set", ["-c", "a", "b", "c"]) }.should \
        raise_error(KV::Error, "too many arguments")
    end

    it "should read full nodepaths from input with -f" do
      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "test/1#key1: value1"
        f.puts "test/1#key1: value2"
        f.puts "test/2#key1: value1"
      end

      KV::Command.new(@kvdb_path).run("set", ["-cf", data_file])
      kv = KV.new(:path => @kvdb_path)
      kv.nodes.should eq(["test/1", "test/2"])
      n = kv.node("test/1")
      n["key1"].should eq(["value1", "value2"])
      n = kv.node("test/2")
      n["key1"].should eq("value1")
    end

    it "should fail a -f full update that creates a node without -c" do
      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "test/1#key1: value1"
        f.puts "test/1#key1: value2"
        f.puts "test/2#key1: value1"
      end

      expect { KV::Command.new(@kvdb_path).run("set", ["-f", data_file]) }.should \
        raise_error(KV::Error, "node test/1 does not exist, and -c not given")
    end

    it "should default to replacing keys with -f" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("key1", "value1")
      n.save

      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "test/1#key1: value2"
      end

      KV::Command.new(@kvdb_path).run("set", ["-f", data_file])
      n = kv.node("test/1", true)
      n["key1"].should eq("value2")
    end

    it "should append keys with -f -a" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("key1", "value1")
      n.save

      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "test/1#key1: value2"
      end

      KV::Command.new(@kvdb_path).run("set", ["-af", data_file])
      n = kv.node("test/1", true)
      n["key1"].should eq(["value1", "value2"])
    end

    it "should treat the entire set as a transaction, and abort all changes if one update fails" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("key1", "value1")
      n.save

      data_file = File.join(@tmp_dir, "data.tmp")
      File.open(data_file, "w+") do |f|
        f.puts "test/1#key1: value2"
        f.puts "test/2#key1: value2"
      end

      expect do
        KV::Command.new(@kvdb_path).run("set", ["-f", data_file])
      end.should raise_error(KV::Error,
                             "node test/2 does not exist, and -c not given")
      n = kv.node("test/1", true)
      n["key1"].should eq("value1")
    end
  end

  describe '#print' do
    it "should error if the node does not exist" do
      $kvdb_path = @kvdb_path

      stdout, stderr = wrap_output do
        expect do
          KV::Command.new(@kvdb_path).run("print", ["test#foo"])
        end.should raise_error(KV::Error, "node test does not exist")
      end
      stdout.should eq('')
    end

    it "should print a variable" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      n = kv.node("test")
      n.set("foo", "bar")
      n.save

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("print", ["test#foo"])
      end
      stdout.should eq("bar\n")
    end

    it "should print a variable with full keypath if -v verbose" do
      $kvdb_path = @kvdb_path
      kv = KV.new(:path => $kvdb_path)
      n = kv.node("test")
      n.set("foo", "bar")
      n.save

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("print", ["-v", "test#foo"])
      end
      stdout.should eq("test#foo: bar\n")
    end

    it "should require exactly one argument" do
      expect { KV::Command.new(@kvdb_path).run("print", []) }.should \
        raise_error(KV::Error, "print takes one argument")

      expect { KV::Command.new(@kvdb_path).run("print", ["a", "b"]) }.should \
        raise_error(KV::Error, "print takes one argument")
    end
  end # describe #print

  describe '#cp' do
    it "should copy a node" do
      kv = KV.new(:path => @kvdb_path)
      n1 = kv.node("test/1")
      n1.add("key1", "value1")
      n1.add("key1", "value2")
      n1.add("key2", "value")
      n1.save

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("cp", ["test/1", "test/2"])
      end
      stdout.should eq('')

      n2 = kv.node("test/2")
      n2.attrs.to_hash.sort.should eq(n1.attrs.to_hash.sort)
    end

    it "should fail when the source node does not exist" do
      expect do
        KV::Command.new(@kvdb_path).run("cp", ["test/1", "test/2"])
      end.should raise_error(KV::Error, "node test/1 does not exist")
    end

    it "should fail when the dest node already exists" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("key1", "value1")
      n.save
      n = kv.node("test/2")
      n.add("key1", "value1")
      n.save

      expect do
        KV::Command.new(@kvdb_path).run("cp", ["test/1", "test/2"])
      end.should raise_error(KV::Error, "node test/2 already exists")
    end
  end # describe #cp

  describe '#rm' do
    it "should delete a node" do
      kv = KV.new(:path => @kvdb_path)
      n1 = kv.node("test/1")
      n1.add("key1", "value1")
      n1.save

      kv.node?("test/1").should eq(true)

      stdout, stderr = wrap_output do
        KV::Command.new(@kvdb_path).run("rm", ["test/1"])
      end
      stdout.should eq('')

      kv = KV.new(:path => @kvdb_path)
      kv.node?("test/1").should eq(false)
    end

    it "should fail when the node does not exist" do
      expect do
        KV::Command.new(@kvdb_path).run("rm", ["test/1"])
      end.should raise_error(KV::Error, "node test/1 does not exist")
    end
  end # describe #rm

  describe '#edit' do
    it "should run env \$EDITOR with a temp file path, and apply changes" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("key1", "value1")
      n.save

      data_file = File.join(@tmp_dir, "kvedit")
      File.open(data_file, "w+") do |f|
        f.puts "key1: value2"
      end

      ENV["EDITOR"] = "cp #{data_file}"
      KV::Command.new(@kvdb_path).run("edit", ["test/1"])

      n = kv.node("test/1", true)
      n["key1"].should eq("value2")
    end

    it "should handle attribute deletion" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("key1", "value1")
      n.add("key2", "value1")
      n.save

      data_file = File.join(@tmp_dir, "kvedit")
      File.open(data_file, "w+") do |f|
        f.puts "key1: value2"
      end

      ENV["EDITOR"] = "cp #{data_file}"
      KV::Command.new(@kvdb_path).run("edit", ["test/1"])

      n = kv.node("test/1", true)
      n["key1"].should eq("value2")
      n.attrs.to_hash.member?("key2").should eq(false)
    end

    it "should abort the edit if EDITOR exits non-zero" do
      kv = KV.new(:path => @kvdb_path)
      n = kv.node("test/1")
      n.add("key1", "value1")
      n.save

      script_file = File.join(@tmp_dir, "kvedit")
      File.open(script_file, "w+") do |f|
        f.puts '#!/bin/sh'
        f.puts 'echo key1: value2 >> $1'
        f.puts 'exit 4'
      end
      FileUtils.chmod(0755, script_file)

      ENV["EDITOR"] = script_file
      expect do
        KV::Command.new(@kvdb_path).run("edit", ["test/1"])
      end.should raise_error(KV::Error, "aborting edit, editor exited 4")

      n = kv.node("test/1", true)
      n["key1"].should eq("value1")
    end
  end # describe #edit
end # describe KV::Command
