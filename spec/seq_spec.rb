# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Seq::ISeq do
  let(:seq) do
    Class.new do
      include Rouge::Seq::ISeq
      def to_a; [:q]; end
    end.new
  end

  describe "#seq" do
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

  describe "#more" do
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

  describe "#cons" do
    let(:head) { double("head") }

    before { Rouge::Seq::Cons.should_receive(:new).with(head, seq) }
    it { seq.cons(head) }
  end

  describe "#[]" do
    let(:numbers) { Rouge::Seq::Cons[1, 2, 3] }

    it { numbers[0].should eq 1 }
    it { numbers[1].should eq 2 }

    # XXX: unlike Clojure. Thoughts?
    it { numbers[5].should eq nil }

    it { numbers[-1].should eq 3 }
    it { numbers[-2].should eq 2 }

    # XXX: or generic seqs/lazyseqs/arrayseqs ...?
    # to preserve Ruby interop probably straight Arrays.
    # We won't be using this form from Rouge itself anyway.
    it { numbers[0..-1].should eq [1, 2, 3] }
    it { numbers[0..-2].should eq [1, 2] }
    it { numbers[0...-2].should eq [1] }
    it { numbers[2...-1].should eq [] }
    it { numbers[2..-1].should eq [3] }
  end

  describe "#each" do
    it "should return an enumerator without a block" do
      Rouge::Seq::Cons[1].each.should be_an_instance_of Enumerator
    end
  end
end

describe Rouge::Seq::Cons do
  describe ".new" do
    it { expect { Rouge::Seq::Cons.new(1, Rouge::Seq::Empty)
                }.to_not raise_exception }

    it { expect { Rouge::Seq::Cons.new(1, nil)
                }.to_not raise_exception }

    it { expect { Rouge::Seq::Cons.new(1, Rouge::Seq::Cons[:x])
                }.to_not raise_exception }

    it { expect { Rouge::Seq::Cons.new(1, Rouge::Seq::Array.new([], 0))
                }.to_not raise_exception }

    it { expect { Rouge::Seq::Cons.new(1, "blah")
                }.to raise_exception(ArgumentError) }
  end

  describe ".[]" do
    it { Rouge::Seq::Cons[].should eq Rouge::Seq::Empty }
    it { Rouge::Seq::Cons[1].
             should eq Rouge::Seq::Cons.new(1, Rouge::Seq::Empty) }
    it { Rouge::Seq::Cons[1].should eq Rouge::Seq::Cons.new(1, nil) }
    it { Rouge::Seq::Cons[1, 2].
             should eq Rouge::Seq::Cons.new(
                1, Rouge::Seq::Cons.new(2, Rouge::Seq::Empty)) }
    it { Rouge::Seq::Cons[1, 2, 3].
        should eq Rouge::Seq::Cons.new(1,
                  Rouge::Seq::Cons.new(2,
                  Rouge::Seq::Cons.new(3, Rouge::Seq::Empty))) }
  end

  describe "#inspect" do
    it { Rouge::Seq::Cons[].inspect.should eq "()" }
    it { Rouge::Seq::Cons[1].inspect.should eq "(1)" }
    it { Rouge::Seq::Cons[1, 2].inspect.should eq "(1 2)" }
    it { Rouge::Seq::Cons[1, 2, 3].inspect.should eq "(1 2 3)" }
    it { Rouge::Seq::Cons[1, 2, 3].tail.inspect.should eq "(2 3)" }
  end

  describe "the ISeq implementation" do
    subject { Rouge::Seq::Cons[1, 2, 3] }

    describe "#first" do
      its(:first) { should eq 1 }
    end

    describe "#next" do
      its(:next) { should be_an_instance_of Rouge::Seq::Cons }
      its(:next) { should eq Rouge::Seq::Cons[2, 3] }
      it { subject.next.next.next.should eq nil }
    end
  end
end

describe Rouge::Seq do
  describe ".seq" do
    #it { Rouge::Seq.seq(
  end
end

# vim: set sw=2 et cc=80:
