# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Seq::ASeq do
  let(:seq) do
    Class.new do
      include Rouge::Seq::ASeq
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

  describe "#==" do
    it { Rouge::Seq::Array.new([:q], 0).should eq seq }
    it { Rouge::Seq::Array.new([:q, :r], 0).
             should eq Rouge::Seq::Cons[:q, :r] }
  end

  describe "#each" do
    it { Rouge::Seq::Cons[1].each.should be_an_instance_of Enumerator }
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

  describe "the ASeq implementation" do
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

describe Rouge::Seq::Array do
  describe "#first" do
    it { Rouge::Seq::Array.new([:a, :b, :c], 0).first.should eq :a }
    it { Rouge::Seq::Array.new([:a, :b, :c], 1).first.should eq :b }
    it { Rouge::Seq::Array.new([:a, :b, :c], 2).first.should eq :c }
  end

  describe "#next" do
    subject { Rouge::Seq::Array.new([:a, :b, :c], 0).next }

    it { should be_an_instance_of Rouge::Seq::Array }
    it { should eq [:b, :c] }
  end
end

describe Rouge::Seq::Lazy do
  let(:sentinel) { double("sentinel") }
  let(:trigger) { Rouge::Seq::Lazy.new(lambda { sentinel.call }) }
  let(:non_seq) { Rouge::Seq::Lazy.new(lambda { 7 }) }
  let(:error) { Rouge::Seq::Lazy.new(lambda { raise "boom" }) }

  describe "not evalled until necessary" do
    context "not realised" do
      before { sentinel.should_not_receive(:call) }
      it { trigger }
    end

    context "realised" do
      before { sentinel.should_receive(:call).and_return [1, 2] }

      it { trigger.seq.should eq [1, 2] }
      it { trigger.first.should eq 1 }
      it { trigger.next.should eq [2] }
    end
  end

  describe "not multiply evalled on non-seq" do
    it do
      # Weird, but most similar to Clojure (by experiment).
      expect { non_seq.seq }.to raise_exception
      expect { non_seq.seq.should be Rouge::Seq::Empty
             }.to_not raise_exception
    end
  end

  describe "multiply evalled on error" do
    it do
      expect { error.seq }.to raise_exception
      expect { error.seq }.to raise_exception
    end
  end
end

describe Rouge::Seq do
  describe ".seq" do
    context Array do
      subject { Rouge::Seq.seq([:a]) }
      it { should be_an_instance_of Rouge::Seq::Array }
      it { should eq Rouge::Seq::Array.new([:a], 0) }

      let(:arrayseq) { Rouge::Seq::Array.new([:a], 0) }
      it { Rouge::Seq.seq(arrayseq).should be arrayseq }
    end

    context Set do
      subject { Rouge::Seq.seq(Set.new([1, 2, 3])) }
      it { should be_an_instance_of Rouge::Seq::Array }
      it { should eq Rouge::Seq::Array.new([1, 2, 3], 0) }
    end

    context Hash do
      subject { Rouge::Seq.seq({:a => "a", :b => "b"}) }
      it { should be_an_instance_of Rouge::Seq::Array }
      it { should eq Rouge::Seq::Array.new([[:a, "a"], [:b, "b"]], 0) }
    end

    context String do
      subject { Rouge::Seq.seq("foo") }
      it { should be_an_instance_of Rouge::Seq::Array }
      it { should eq Rouge::Seq::Array.new(['f', 'o', 'o'], 0) }
    end

    context Enumerator do
      subject { Rouge::Seq.seq(1.upto(3)) }
      it { should be_an_instance_of Rouge::Seq::Array }
      it { should eq Rouge::Seq::Array.new([1, 2, 3], 0) }
    end
  end
end

# vim: set sw=2 et cc=80:
