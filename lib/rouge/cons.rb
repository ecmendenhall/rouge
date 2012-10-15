# encoding: utf-8
require 'rouge/seq'

class Rouge::Cons
  include Rouge::Seq::ISeq

  def initialize(head, tail)
    if !tail.is_a?(Rouge::Seq::ISeq)
      raise ArgumentError,
        "tail should be an ISeq, not #{tail.inspect}"
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
    Rouge::Seq.seq @tail
  end

  def self.[](*elements)
    head = Rouge::Seq::Empty
    (elements.length - 1).downto(0).each do |i|
      head = new(elements[i], head.freeze)
    end

    head.freeze
  end

  attr_reader :head, :tail
end

# vim: set sw=2 et cc=80:
