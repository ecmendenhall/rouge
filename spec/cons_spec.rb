# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Cons do
  describe "the constructor" do
    it { expect { Rouge::Cons.new(1, Rouge::Seq::Empty)
                }.to_not raise_exception }

    it { expect { Rouge::Cons.new(1, Rouge::Cons[:x])
                }.to_not raise_exception }

    it { expect { Rouge::Cons.new(1, Rouge::Seq::Array.new([], 0))
                }.to_not raise_exception }

    it { expect { Rouge::Cons.new(1, "blah")
                }.to raise_exception(ArgumentError) }
  end

  describe "the multi-constructor" do
    it "should create a Cons for each element" do
      Rouge::Cons[].should eq Rouge::Seq::Empty
      Rouge::Cons[1].should eq Rouge::Cons.new(1, Rouge::Seq::Empty)
      Rouge::Cons[1, 2].
          should eq Rouge::Cons.new(1, Rouge::Cons.new(2, Rouge::Seq::Empty))
      Rouge::Cons[1, 2, 3].
          should eq Rouge::Cons.new(1,
                    Rouge::Cons.new(2,
                    Rouge::Cons.new(3, Rouge::Seq::Empty)))
    end
  end

  describe "Ruby pretty-printing" do
    describe "resemblance to the constructor" do
      it { Rouge::Cons[].inspect.should eq "Rouge::Cons[]" }
      it { Rouge::Cons[1].inspect.should eq "Rouge::Cons[1]" }
      it { Rouge::Cons[1, 2].inspect.should eq "Rouge::Cons[1, 2]" }
      it { Rouge::Cons[1, 2, 3].inspect.should eq "Rouge::Cons[1, 2, 3]" }
      it { Rouge::Cons[1, 2, 3].tail.inspect.should eq "Rouge::Cons[2, 3]" }
    end
  end

  describe "the ISeq implementation" do
    let(:cons) { Rouge::Cons[1, 2, 3] }

    describe "the first implementation" do
      it { cons.first.should eq 1 }
    end

    describe "the next implementation" do
      it { cons.next.should be_an_instance_of Rouge::Cons }
      it { cons.next.should eq Rouge::Cons[2, 3] }
    end
  end
end

# vim: set sw=2 et cc=80:
