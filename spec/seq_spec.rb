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
      seq.more.should eq [] # XXX: [] or otherwise?
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
end

describe Rouge::Seq do
  describe "the seq method" do
    #it { Rouge::Seq.seq(
  end
end

# vim: set sw=2 et cc=80:
