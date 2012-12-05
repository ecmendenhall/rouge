# encoding: utf-8

# Functions, clases and modules concerning the `seq' sequence abstraction.
module Rouge::Seq
  # An empty seq.
  Empty = Object.new

  # A sequence consisting of a head (element) and tail (another sequence).
  # Filled out below after ASeq's definition.
  class Cons; end

  # A module purely to indicate that this is a seqable type.  Any class
  # including ISeq should define a #seq method.
  module ISeq; end

  # A partial implementation of ISeq.  You supply #first and #next, it gives:
  #
  #  - #cons
  #  - #inspect
  #  - #to_s
  #  - #seq
  #  - #length (#count)
  #  - #[]
  #  - #==
  #  - #each
  #  - #map
  #  - #to_a
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
      nseq = self.next
      if nseq.nil?
        Empty
      else
        nseq
      end
    end

    def cons(head)
      Cons.new(head, self)
    end

    def length
      len = 0
      cursor = self

      while cursor != Empty
        len += 1
        cursor = cursor.more
      end

      len
    end

    alias count length

    def [](idx)
      return to_a[idx] if idx.is_a? Range

      cursor = self

      idx += self.length if idx < 0

      while idx > 0
        idx -= 1
        cursor = cursor.more
        return nil if cursor == Empty
      end

      cursor.first
    end

    def ==(seq)
      if seq.is_a?(ISeq)
        return self.to_a == seq.to_a
      end

      if seq.is_a?(::Array)
        return self.to_a == seq
      end

      false
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

      result = []
      self.each {|elem| result << block.call(elem)}
      result
    end

    def to_a
      r = []
      self.each {|e| r << e}
      r
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
      length = elements.length
      return Empty if length.zero?

      head = nil
      (length - 1).downto(0).each do |i|
        head = new(elements[i], head.freeze)
      end

      head.freeze
    end

    attr_reader :head, :tail
  end

  # A seq over a Ruby Array.
  class Array
    include ASeq

    def initialize(array, idx)
      @array, @idx = array, idx
    end

    def first
      @array[@idx]
    end

    def next
      if @idx + 1 < @array.length
        Array.new(@array, @idx + 1)
      end
    end
  end

  # A lazy seq; contains the body (thunk) which is a lambda to get the "real"
  # seq.  Once evaluated (realised), the result is cached.
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
        @body = nil
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

  # An error thrown when we try to do a seq operation on something that's not
  # seqable.
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
    when Enumerator
      seq(form.to_a)
    else
      raise UnknownSeqError, form.inspect
    end
  end
end

# vim: set sw=2 et cc=80:
