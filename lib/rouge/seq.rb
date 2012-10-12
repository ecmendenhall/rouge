# encoding: utf-8

module Rouge::Seq
  module ISeq
    def seq; self; end

    def first; raise NotImplementedError; end

    def next; raise NotImplementedError; end

    def more
      s = self.next
      return [] if s.nil?
      s
    end

    def cons(o); raise NotImplementedError; end
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
