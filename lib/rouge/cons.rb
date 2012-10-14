# encoding: utf-8
require 'rouge/seq'

class Rouge::Cons
  include Rouge::Seq::ISeq

  def initialize(head, tail)
    if !tail.is_a?(Rouge::Seq::ISeq)
      raise ArgumentError,
        "tail should be a Rouge::Cons or Empty, not #{tail}"
    end

    @head, @tail = head, tail
  end

  def inspect
    "Rouge::Cons[#{to_a.map(&:inspect).join ", "}]"
  end

  def to_s; inspect; end

  def first
    @head
  end

  def next
    Rouge::Seq.seq
  end


  def self.[](*elements)
    head = Empty
    (elements.length - 1).downto(0).each do |i|
      head = new(elements[i], head.freeze)
    end

    head.to_a
    head.freeze
  end

  def ==(cons)
    cons.is_a?(Rouge::Cons) and to_a == cons.to_a
  end

  def to_a
    return @to_a if @to_a

    to_a = [@head]
    cursor = @tail
    while cursor and cursor != Empty
      to_a << cursor.head
      cursor = cursor.tail
    end

    if frozen?
      to_a 
    else
      @to_a = to_a
    end
  end

  def map(&block)
    Rouge::Cons[*to_a.map(&block)]
  end

  def method_missing(sym, *args, &block)
    to_a.send(sym, *args, &block)
  end

  attr_reader :head, :tail
end

Rouge::Cons::Empty = Object.new
class << Rouge::Cons::Empty
  include Rouge::Seq::ISeq

  def each(&block)
    return self.enum_for(:each) if block.nil?
  end
  def length; 0; end
  def [](i); nil; end
  def to_a; []; end
  def inspect; "Rouge::Cons[]"; end
  def to_s; inspect; end

  include Enumerable
end
Rouge::Cons::Empty.freeze

# vim: set sw=2 et cc=80:
