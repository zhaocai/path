# Enchanced Pathname
# Use the composite pattern with a Pathname

require 'pathname'
require 'fileutils'

autoload :Tempfile, 'tempfile'

class Path
  DOTS = %w[. ..]

  attr_reader :path

  class << self
    def new(*args)
      if args.size == 1 and EPath === args[0]
        args[0]
      else
        super(*args)
      end
    end
    alias_method :[], :new

    def here(from = caller)
      new(from.first.split(':').first).expand
    end
    alias_method :file, :here

    def dir
      file(caller).dir
    end

    def relative(path)
      new(path).expand file(caller).dir
    end

    def tmpfile(basename = '', tmpdir = nil, options = nil)
      tempfile = Tempfile.new(basename, *[tmpdir, options].compact)
      file = new tempfile
      if block_given?
        begin
          yield file
        ensure
          tempfile.close
          tempfile.unlink if file.exist?
        end
      end
      file
    end
    alias_method :tempfile, :tmpfile

    def tmpdir(prefix_suffix = nil, *rest)
      require 'tmpdir'
      dir = new Dir.mktmpdir(prefix_suffix, *rest)
      if block_given?
        begin
          yield dir
        ensure
          FileUtils.remove_entry_secure(dir) rescue nil
        end
      end
      dir
    end
  end

  def initialize(*parts)
    path = parts.size > 1 ? parts.join(File::SEPARATOR) : parts.first
    @path = case path
    when Pathname
      path
    when String
      Pathname.new(path)
    when Tempfile
      @_tmpfile = path # We would not want it to be GC'd
      Pathname.new(path.path)
    else
      raise "Invalid arguments: #{parts}"
    end
  end

  def inspect
    "#<#{self.class} #{@path}>"
  end

  def == other
    Path === other and @path == other.path
  end
  alias_method :eql?, :==

  def / part
    join part.to_s
  end

  def base # basename(extname)
    Path.new @path.basename(@path.extname)
  end

  def ext # extname without leading .
    extname = @path.extname
    extname.empty? ? extname : extname[1..-1]
  end

  def without_extension # rm_ext
    dir / base
  end

  def replace_extension(ext)
    ext = ".#{ext}" unless ext.start_with? '.'
    Path.new(without_extension.to_s + ext)
  end

  def entries
    (Dir.entries(@path) - DOTS).map { |entry| Path.new(@path, entry) }
  end

  def glob(pattern, flags = 0)
    Dir.glob(join(pattern), flags).map { |path|
      Path.new(path)
    }
  end

  def rm_rf
    FileUtils.rm_rf(@path)
  end

  def mkdir_p
    FileUtils.mkdir_p(@path)
  end

  def write(contents, open_args = nil)
    if IO.respond_to? :write
      IO.write(@path, contents, *[open_args].compact)
    else
      open('w', *[open_args].compact) { |f| f.write(contents) }
    end
  end

  (Pathname.instance_methods(false) - instance_methods(false)).each do |meth|
    class_eval <<-METHOD, __FILE__, __LINE__+1
      def #{meth}(*args, &block)
        result = @path.#{meth}(*args, &block)
        Pathname === result ? #{self}.new(result) : result
      end
    METHOD
  end

  alias_method :to_path, :to_s unless method_defined? :to_path
  alias_method :to_str, :to_s unless method_defined? :to_str

  alias_method :expand, :expand_path
  alias_method :dir, :dirname
  alias_method :relative_to, :relative_path_from
end

EPath = Path # to meet everyone's expectations

unless defined? NO_EPATH_GLOBAL_FUNCTION
  def Path(*args)
    Path.new(*args)
  end
end
