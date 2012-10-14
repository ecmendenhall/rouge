# encoding: utf-8

module Rouge::Seq
  Empty = Class.new do
    def inspect; "Rouge::Cons[]"; end
    def to_s; inspect; end

    def first; nil; end
    def next; nil; end
  end.new

  module ISeq
    include Enumerable

    def seq; self; end

    def first; raise NotImplementedError; end

    def next; raise NotImplementedError; end

    def [](i)
      cursor = self
      while i > 0
        cursor = cursor.next
        i -= 1
        if cursor.nil?
          raise IndexError
        end
      end
      cursor.first
    end

    def more
      s = self.next
      return Empty if s.nil?
      s
    end

    def cons(o)
      Rouge::Cons.new(o, self)
    end

    def ==(cons)
      self.to_a == cons.to_a
    end

    def each(&block)
      return self.enum_for(:each) if block.nil?

      yield self.first

      cursor = self.tail
      while cursor
        yield cursor.first
        cursor = cursor.next
      end

      self
    end

    def map(&block)
      return self.enum_for(:map) if block.nil?

      r = []
      self.each {|e| r << block.call(e)}
      r
    end

    def to_a
      r = []
      self.each {|e| r << e}
      r
    end

    def map(&block)
      Rouge::Cons[*to_a.map(&block)]
    end
  end

  class << Empty
    include ISeq
  end

  class Array
    include ISeq

    def initialize(array, i)
      @array, @i = array, i
    end
  end

  def self.seq(form)
    case form
    when ISeq
      form
    else
      raise "TODO; unknown seq"
    end
  end
end

# vim: set sw=2 et cc=80:
