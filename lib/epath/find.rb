class Path
  #
  # Path#find is an iterator to traverse a directory tree in a depth first
  # manner.  It yields a Path for each file under "this" directory.
  #
  # Since it is implemented by <tt>find.rb</tt>, <tt>Find.prune</tt> can be used
  # to control the traversal.
  #
  # If +self+ is <tt>.</tt>, yielded pathnames begin with a filename in the
  # current directory, not <tt>./</tt>.
  #
  def find # :yield: pathname
    return to_enum(__method__) unless block_given?
    require 'find'
    if @path == '.'
      Find.find(@path) {|f| yield Path.new(f.sub(%r{\A\./}, '')) }
    else
      Find.find(@path) {|f| yield Path.new(f) }
    end
  end
end
