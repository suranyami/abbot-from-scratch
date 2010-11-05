require "spec_helper"

describe SproutCore::Compiler::VirtualFileSystem do
  MockTime = Struct.new(:now)

  def write
    @fs.write(file, "hello zoo")
  end

  shared_examples_for "a virtual file system" do
    before do
      @time = MockTime.new
      @time.now = Time.now
      @fs = SproutCore::Compiler::VirtualFileSystem.new(@time)
    end

    it "knows that non-existant files don't exist" do
      @fs.exist?(file).should be_false
    end

    it "can create a new file" do
      write
      @fs.read(file).should == "hello zoo"
    end

    it "knows that existant files exist" do
      write
      @fs.exist?(file).should be_true
    end

    it "knows that deleted files don't exist" do
      write
      @fs.delete(file)
      @fs.exist?(file).should be_false
    end

    it "raises an error when trying to delete non-existant files" do
      write
      lambda { @fs.delete("#{root}/zomg") }.should raise_error(Errno::ENOENT)
    end

    it "knows the mtime of newly created files" do
      now = @time.now = Time.now

      write
      @fs.mtime(file).should == now
    end

    it "knows the mtime of updated files" do
      @time.now = Time.now - 100
      write
      now = @time.now = Time.now
      write
      @fs.mtime(file).should == now
    end

    describe "looking for a file under a file" do
      before { write }

      it "raises an error when looking for mtime" do
        lambda { @fs.mtime("#{file}/my") }.should raise_error(Errno::ENOTDIR)
      end

      it "raises an error when trying to delete" do
        lambda { @fs.delete("#{file}/my") }.should raise_error(Errno::ENOTDIR)
      end

      it "raises an error when trying to create" do
        lambda { @fs.write("#{file}/my", "nope") }.should raise_error(Errno::ENOTDIR)
      end
    end
  end

  describe "at the root" do
    it_should_behave_like "a virtual file system"

    let(:file) { "/zoo" }
    let(:root) { "/" }
  end

  describe "nested" do
    it_should_behave_like "a virtual file system"

    let(:file) { "/zoo/bar" }
    let(:root) { "/zoo" }
  end

  describe "virtual or real file system" do
    include TmpDir

    before do
      @fs = SproutCore::Compiler::VirtualOrRealFileSystem.new
      SproutCore::Spec::DirectoryBuilder.new(tmp) do
        file("zoo") do
          write "hello real-file zoo"
        end
      end
      @mtime = Time.now
      @ondisk = File.join(tmp, "zoo")
    end

    it "reads from the real file system" do
      @fs.exist?(@ondisk).should be_true
      @fs.read(@ondisk).should == "hello real-file zoo"
    end

    it "knows the mtime of files on the file system" do
      @fs.mtime(@ondisk).should be_close(@mtime, 1)
    end

    it "raises on mtime if the file doesn't exist" do
      lambda { @fs.mtime("/zoo/my/god") }.should raise_error(Errno::ENOENT)
    end
  end
end