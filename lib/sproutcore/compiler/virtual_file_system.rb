module SproutCore
  module Compiler
    # A simple virtual file system that can be used to compile
    # a tree to memory instead of disk.
    #
    # VirtualFile may not be used interchangably with File. Instead,
    # use the VirtualFile API to interact with files.
    #
    # In some cases, you might want to allow files to be read from
    # the real file system if they cannot be found in the virtual
    # file system. In this case, use the VirtualOrRealFile API,
    # which is identical to the VirtualFile API, but will fall back
    # to the real file system if a file cannot be found in the
    # virtual file system.
    class VirtualFileSystem
      VirtualFile = Struct.new(:contents, :mtime)

      def self.instance(time = Time)
        @instance ||= new(time)
      end

      def initialize(time = Time)
        @files = {}
        @time  = time
      end

      # @param [#path] path the file to check existence of
      # @returns [boolean]
      #
      # @forwards VirtualFile#lookup_file
      def self.exist?(path)
        instance.exist?(path)
      end

      def exist?(path)
        file = lookup_file(path)
        file.is_a?(VirtualFile)
      end

      # @param [#path] path the file to return the contents of
      # @returns [String] the contents of the file
      #
      # @forwards VirtualFile#lookup_file
      def self.read(path)
        instance.read(path)
      end

      def read(path)
        file = lookup_file(path)
        file.is_a?(VirtualFile) && file.contents
      end

      # @param [#path] path the path to write to
      # @param [String] contents the contents of the file
      #
      # @forwards VirtualFile#create_file
      def self.write(path, contents)
        instance.write(path, contents)
      end

      def write(path, contents)
        create_file(path, contents)
      end

      def self.delete(path)
        instance.delete(path)
      end

      def delete(path)
        delete_file(path)
      end

      # @param [#path] path the path of the file
      # @returns [Time] the last time the file was updated
      #
      # @raises [Errno::ENOENT] if the file does not exist
      #
      # @forwards VirtualFile#lookup_file
      def self.mtime(path)
        instance.mtime(path)
      end

      def mtime(path)
        file = lookup_file(path)

        if file.is_a?(VirtualFile)
          file.mtime
        else
          raise Errno::ENOENT, "No such file, #{path}"
        end
      end

    private
      # raises [Errno::ENOTDIR] if any part of the path other
      #   than the very end references a file, rather than
      #   a directory.
      def create_file(path, contents)
        location = @files
        current_path = ""
        dirname = File.dirname(path)
        dirname = nil if dirname == "."

        File.dirname(path).split("/").each do |segment|
          next if segment.empty?

          if location[segment].is_a?(String)
            raise Errno::ENOTDIR "#{current_path}/#{segment} is a file, not a directory"
          end

          location[segment] ||= {}
          location = location[segment]
          current_path = File.join(current_path, segment)
        end

        filename = File.basename(path)

        location[filename] = VirtualFile.new(contents, @time.now)
      end

      # raises [Errno::ENOTDIR] if any part of the path other
      #   than the very end references a file, rather than
      #   a directory.
      def lookup_file(path)
        current_path = ""

        path.split("/").inject(@files) do |location, segment|
          break if location.nil?
          next location if segment.empty?

          if location.is_a?(String)
            raise Errno::ENOTDIR, "#{current_path} is a file, not a directory"
          end

          current_path = File.join(current_path, segment)
          location[segment]
        end
      end

      def delete_file(path)
        current_path = ""
        location     = @files

        segments = path.split("/")
        filename = segments.pop

        segments.each do |segment|
          if location.nil?
            raise Errno::ENOENT, "#{current_path} does not exist"
          elsif segment.empty?
            next
          end

          current_path = File.join(current_path, segment)
          location = location[segment]
        end

        if location.is_a?(String)
          raise Errno::ENOTDIR, "#{current_path} is a file, not a directory"
        else
          location.delete(filename)
        end
      end
    end

    # A subclass of VirtualFile that falls back to the real file
    # system for reads if a File cannot be found in the virtual
    # file system
    class VirtualOrRealFileSystem < VirtualFileSystem
      def exist?(file)
        super || File.exist?(file)
      end

      def read(path)
        super || File.read(path)
      end

      def mtime(path)
        super
      rescue Errno::ENOENT
        File.mtime(path)
      end
    end
  end
end
