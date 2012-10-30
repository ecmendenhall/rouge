# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Cons do
  describe "the multi-constructor" do
    context "creating a Cons for each element" do
      it { Rouge::Cons[].should eq Rouge::Cons::Empty }
      it { Rouge::Cons[1].should eq Rouge::Cons.new(1, Rouge::Cons::Empty) }
      it { Rouge::Cons[1, 2].
          should eq Rouge::Cons.new(1, Rouge::Cons.new(2, Rouge::Cons::Empty)) }
      it { Rouge::Cons[1, 2, 3].
            should eq Rouge::Cons.new(1,
                      Rouge::Cons.new(2,
                      Rouge::Cons.new(3, Rouge::Cons::Empty))) }
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

  describe "the index-access getter" do
    describe "geting single elements" do
      it { Rouge::Cons[1, 2, 3][0].should eq 1 }
      it { Rouge::Cons[1, 2, 3][1].should eq 2 }
    end

    describe "returning nil if an element is not present" do
      it { Rouge::Cons[1, 2, 3][5].should eq nil }
    end

    describe "working withing negative indices" do
      it { Rouge::Cons[1, 2, 3][-1].should eq 3 }
      it { Rouge::Cons[1, 2, 3][-2].should eq 2 }
    end

    describe "returning Arrays for ranges" do
      it { Rouge::Cons[1, 2, 3][0..-1].should eq [1, 2, 3] }
      it { Rouge::Cons[1, 2, 3][0..-2].should eq [1, 2] }
      it { Rouge::Cons[1, 2, 3][0...-2].should eq [1] }
      it { Rouge::Cons[1, 2, 3][2...-1].should eq [] }
      it { Rouge::Cons[1, 2, 3][2..-1].should eq [3] }
    end
  end

  describe "the 'each' method" do
    describe "returning an enumerator without a block" do
      it { Rouge::Cons[1].each.should be_an_instance_of Enumerator }
    end
  end
end

# vim: set sw=2 et cc=80:
