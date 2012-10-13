# encoding: utf-8
require 'rouge/metadata'

class Rouge::Symbol
  include Rouge::Metadata

  # The symbols for t/f/n are the Ruby objects themselves.
  LOOKUP = {
    :true => true,
    :false => false,
    :nil => nil,
  }
  
  KNOWNS = {
    :/ => [nil, :/],
    :"./" => [nil, :"./"],
    :"rouge.core//" => [:"rouge.core", :/],
    :"rouge.core/./" => [:"rouge.core", :"./"]
  }

  CACHE = {}

  def initialize(sym)
    if r = KNOWNS[sym]
      @ns = r[0]
      @name = r[1]
    else
      str = sym.to_s
      solidus = str.rindex('/')
      if solidus
        @ns = str[0...solidus].intern
        @name = str[solidus + 1..-1].intern
      else
        @ns = nil
        @name = sym
      end
    end

    @ns_s = @ns.to_s unless @ns.nil?
    @name_s = @name.to_s

    # split(sep, 0) means a trailing '.' won't become an empty component.  (0
    # is default)  Contrast with split(sep, -1).
    @name_parts =
      @name_s.length > 1 ? @name_s.split('.', 0).map(&:intern) : [@name]

    @new_sym = (@name_s[-1] == ?. and @name_s.length > 1)
  end

  def self.[](inner)
    return LOOKUP[inner] if LOOKUP.include? inner
    c = CACHE[inner]
    return c.dup if c
    # Note: don't cache symbols themselves, they may have metadata.
    c = new inner
    CACHE[inner] = c.dup.freeze
    c
  end

  def inspect
    "Rouge::Symbol[#{:"#{@ns ? "#@ns/" : ""}#@name".inspect}]"
  end

  def to_s; inspect; end

  def ==(right)
    right.is_a?(Rouge::Symbol) and right.ns == @ns and right.name == @name
  end

  attr_reader :ns, :name, :ns_s, :name_s, :name_parts, :new_sym
end

# vim: set sw=2 et cc=80:
