# encoding: utf-8
require 'rouge/context'
require 'rouge/builtins'
require 'rouge/var'
require 'rouge/atom'

class Rouge::Namespace
  class VarNotFoundError < StandardError; end
  class RecursiveNamespaceError < StandardError; end

  attr_reader :name, :refers, :table

  @namespaces = {}

  def initialize(name)
    unless name.is_a? Symbol
      raise ArgumentError, "bad ns name"
    end

    @name = name
    @refers = []
    @table = {}
  end

  def inspect
    "#<Rouge::Namespace: @name=#{@name.inspect}, " \
    "@refers=[#{@refers.map(&:inspect).join(", ")}]>"
  end

  def refer(ns)
    if ns.name == @name
      raise RecursiveNamespaceError, "#@name will not refer #{ns.name}"
    end

    unless @refers.include?(ns)
      @refers << ns
    end

    self
  end

  def [](key)
    if @table.include? key
      return @table[key]
    end

    @refers.each do |ns|
      begin
        return ns[key]
      rescue VarNotFoundError
        # no-op
      end
    end

    raise VarNotFoundError, key
  end

  def set_here(key, value)
    @table[key] = Rouge::Var.new(@name, key, value)
  end

  def intern(key)
    @table[key] ||= Rouge::Var.new(@name, key)
  end

  def read(input)
    Rouge::Reader.new(self, input).lex
  end

  def clear
    @table = {}
    self
  end

  # Returns a hash of all namespaces.
  #
  # @return [Hash]
  #
  # @api public
  def self.all
    @namespaces
  end

  # Returns true if the given namespace ns exists, false otherwise.
  #
  # @param [Symbol] ns the namespace to check for
  #
  # @return [Boolean]
  #
  # @api public
  def self.exists?(ns)
    @namespaces.include?(ns)
  end

  def self.[](ns)
    if exists?(ns)
      @namespaces[ns]
    else
      self[ns] = new(ns)
      @namespaces[ns] = new(ns)
    end
  end

  def self.[]=(ns, value)
    @namespaces[ns] = value
  end

  def self.get(ns)
    @namespaces[ns]
  end

  def self.destroy(ns)
    @namespaces.delete ns
  end
end

class Rouge::Namespace::Ruby
  @@cache = {}

  def [](name)
    return @@cache[name] if @@cache.include? name
    if name =~ /^\$/
      @@cache[name] = Rouge::Var.new(:ruby, name, eval(name.to_s))
    else
      @@cache[name] = Rouge::Var.new(:ruby, name, Kernel.const_get(name))
    end
  rescue NameError
    raise Rouge::Namespace::VarNotFoundError, name
  end

  def set_here(name, value)
    @@cache[name] = Rouge::Var.new(:ruby, name, value)
    Kernel.const_set name, value
  end

  def name
    :ruby
  end

  # Returns the result of calling Object.constants.
  #
  # @return [Array<Symbol>] the list of Ruby constants
  #
  # @api public
  #
  def table
    Object.constants
  end
end

# Create the rouge.builtin namespace.
ns = Rouge::Namespace[:"rouge.builtin"]

Rouge::Builtins.methods(false).reject {|s| s =~ /^_compile_/}.each do |m|
  ns.set_here m, Rouge::Builtin[Rouge::Builtins.method(m)]
end

Rouge::Builtins::SYMBOLS.each do |name, val|
  ns.set_here name, val
end

# Create the ruby namespace.
Rouge::Namespace[:ruby] = Rouge::Namespace::Ruby.new

# vim: set sw=2 et cc=80:
