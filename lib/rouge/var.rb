# encoding: utf-8

class Rouge::Var
  attr_reader :ns, :name

  @@stack = []

  def initialize(ns, name, root=Rouge::Var::UnboundSentinel)
    raise ArgumentError, "bad var ns" unless ns.is_a? Symbol
    raise ArgumentError, "bad var name" unless name.is_a? Symbol

    @ns = ns
    @name = name

    if root == Rouge::Var::UnboundSentinel
      @root = Rouge::Var::Unbound.new(self)
    else
      @root = root
    end
  end

  def ==(other)
    other.is_a?(Rouge::Var) && @ns == other.ns && @name == other.name
  end

  def deref
    @@stack.reverse_each do |map|
      if map.include?(@name)
        return map[@name]
      end
    end

    @root
  end

  def inspect
    "#<Rouge::Var: (#{@ns.inspect}, #{@name.inspect}, #{@root.inspect})>"
  end

  def to_s
    "#'#@ns/#@name"
  end

  def self.push(map)
    @@stack << map
  end

  def self.pop
    @@stack.pop
  end
end

class Rouge::Var::UnboundSentinel
  def self.inspect
    "#<Rouge::Var::UnboundSentinel>"
  end
end

class Rouge::Var::Unbound
  attr_reader :var

  def initialize(var)
    @var = var
  end

  def ==(other)
    @var == other.var
  end

  def inspect
    "#<Rouge::Var::Unbound: #@var>"
  end
end

# vim: set sw=2 et cc=80:
