require "fileutils"

module SproutCore
  module Spec
    class DirectoryBuilder
      def initialize(root, &block)
        @root = root

        FileUtils.mkdir_p(root)

        instance_eval(&block)
      end

      def directory(name, &block)
        new_root = File.join(@root, name)
        DirectoryBuilder.new(new_root, &block)
      end

      def file(name, &block)
        file_name = File.join(@root, name)
        FileBuilder.new(file_name, &block)
      end
    end

    class FileBuilder
      def initialize(path, &block)
          @path = path
          instance_eval(&block)
        end
      end

      def write(body)
        File.open(@path, "wb") do |file|
          file.write(body)
        end
      end

      def append(body)
        File.open(@path, "ab") do |file|
          file.write(body)
        end
      end
    end
  end
end
