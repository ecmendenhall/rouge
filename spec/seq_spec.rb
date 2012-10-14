# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Seq::ISeq do
  let(:seq) { Class.new { include Rouge::Seq::ISeq }.new }

  describe "the seq method" do
    it "should return the original object" do
     seq.seq.should be seq
    end 
  end

  describe "the unimplemented methods" do
    it { expect { seq.first
                }.to raise_exception NotImplementedError }

    it { expect { seq.next
                }.to raise_exception NotImplementedError }
  end

  describe "the more method" do
    it "should return the value of next" do
      r = double("next result")
      seq.should_receive(:next).and_return(r)
      seq.more.should be r
    end

    it "should return an empty list if next returns nil" do
      r = double("next result")
      seq.should_receive(:next).and_return(nil)
      seq.more.should eq Rouge::Seq::Empty
    end
  end

  describe "the cons method" do
    # Test currently fails because Cons' tail doesn't take a seq!
    # (Leave this as failing so we don't accidentally merge it like this.)
    it "should return the object as the head" do
      head = double("head")
      seq.cons(head).should eq Rouge::Cons.new(head, seq)
    end
  end

  describe "the index-access getter" do
    let(:numbers) { Rouge::Cons[1, 2, 3] }

    it "should get single elements" do
      numbers[0].should eq 1
      numbers[1].should eq 2
    end

    # XXX: unlike Clojure. Thoughts?
    it "should return nil if an element is not present" do
      numbers[5].should eq nil
    end

    it "should work with negative indices" do
      numbers[-1].should eq 3
      numbers[-2].should eq 2
    end

    # XXX: or generic seqs/lazyseqs/arrayseqs ...?
    # to preserve Ruby interop probably straight Arrays.
    # We won't be using this form from Rouge itself anyway.
    it "should return Arrays for ranges" do
      numbers[0..-1].should eq [1, 2, 3]
      numbers[0..-2].should eq [1, 2]
      numbers[0...-2].should eq [1]
      numbers[2...-1].should eq []
      numbers[2..-1].should eq [3]
    end
  end

  describe "the each method" do
    it "should return an enumerator without a block" do
      Rouge::Cons[1].each.should be_an_instance_of Enumerator
    end
  end
end

describe Rouge::Seq do
  describe "the seq method" do
    #it { Rouge::Seq.seq(
  end
end

# vim: set sw=2 et cc=80:
