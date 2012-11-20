# encoding: utf-8

module Rouge::Seq
  Empty = Object.new

  class Cons; end

  module ISeq; end

  module ASeq
    include ISeq

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

    alias count length

    def [](i)
      return to_a[i] if i.is_a? Range

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
      (seq.is_a?(ISeq) and self.to_a == seq.to_a) or
        (seq.is_a?(::Array) and self.to_a == seq)
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
    include ASeq

    def inspect; "()"; end
    def to_s; inspect; end

    def seq; nil; end
    def first; nil; end
    def next; nil; end

    def each(&block)
      return self.enum_for(:each) if block.nil?
    end
  end

  Empty.freeze

  class Cons
    include ASeq

    def initialize(head, tail)
      if tail and !tail.is_a?(ISeq)
        raise ArgumentError,
            "tail should be an ISeq, not #{tail.inspect} (#{tail.class})"
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
    include ASeq

    def initialize(array, i)
      @array, @i = array, i
    end

    def first
      @array[@i]
    end

    def next
      if @i + 1 < @array.length
        Array.new(@array, @i + 1)
      end
    end
  end

  class Lazy
    include ISeq

    def initialize(body)
      @body = body
      @realized = false
    end

    def seq
      if @realized
        @result
      else
        @result = Rouge::Seq.seq(@body.call) || Empty
        @realized = true
        @result
      end
    rescue UnknownSeqError
      @realized = true
      @result = Empty
      raise
    end

    def method_missing(sym, *args, &block)
      seq.send(sym, *args, &block)
    end

    def inspect; seq.inspect; end
    def to_s; seq.to_s; end
  end

  UnknownSeqError = Class.new(StandardError)

  def self.seq(form)
    case form
    when ISeq
      form.seq
    when NilClass
      form
    when ::Array
      if form.empty?
        nil
      else
        Rouge::Seq::Array.new(form, 0)
      end
    else
      raise UnknownSeqError
    end
  end
end

# vim: set sw=2 et cc=80:
