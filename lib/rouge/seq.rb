# encoding: utf-8

module Rouge::Seq
  Empty = Object.new

  class Cons; end

  module ISeq
    def inspect
      "(#{to_a.map(&:inspect).join " "})"
    end

    def to_s; inspect; end

    def seq; self; end

    def first; raise NotImplementedError; end
    def next; raise NotImplementedError; end

    def more
      s = self.next
      if s.nil?
        Empty
      else
        s
      end
    end

    def cons(o)
      Cons.new(o, self)
    end

    def length
      l = 0
      cursor = self

      while cursor != Empty
        l += 1
        cursor = cursor.more
      end

      l
    end

    def [](i)
      if i.is_a? Range
        return to_a[i]
      end

      cursor = self

      i += self.length if i < 0

      while i > 0
        i -= 1
        cursor = cursor.more
        return nil if cursor == Empty
      end

      cursor.first
    end

    def ==(seq)
      seq.is_a?(ISeq) and self.to_a == seq.to_a
    end

    def each(&block)
      return self.enum_for(:each) if block.nil?

      yield self.first

      cursor = self.more
      while cursor != Empty
        yield cursor.first
        cursor = cursor.more
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
      Cons[*to_a.map(&block)]
    end
  end

  class << Empty
    include ISeq

    def inspect; "()"; end
    def to_s; inspect; end

    def first; nil; end
    def next; nil; end

    def each(&block)
      return self.enum_for(:each) if block.nil?
    end
  end

  Empty.freeze

  class Cons
    include ISeq

    def initialize(head, tail)
      if tail and !tail.is_a?(ISeq)
        raise ArgumentError, "tail should be an ISeq, not #{tail.inspect}"
      end

      @head, @tail = head, tail
    end

    def first; @head; end
    def next; Rouge::Seq.seq @tail; end

    def self.[](*elements)
      return Empty if elements.length.zero?

      head = nil
      (elements.length - 1).downto(0).each do |i|
        head = new(elements[i], head.freeze)
      end

      head.freeze
    end

    attr_reader :head, :tail
  end

  class Array
    include ISeq

    def initialize(array, i)
      @array, @i = array, i
    end
  end

  def self.seq(form)
    case form
    when ISeq, NilClass
      form
    else
      raise "TODO; unknown seq"
    end
  end
end

# vim: set sw=2 et cc=80:
