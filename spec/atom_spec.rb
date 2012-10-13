# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Atom do
  describe "the constructor" do
    let(:v) { Rouge::Atom.new(:snorlax) }
    
    it "creates an atom with an initial value" do
      v.deref.should eq :snorlax
    end
  end

  describe "equality" do
    let(:a) { Rouge::Atom.new(:raichu) }
    let(:b) { Rouge::Atom.new(:raichu) }

    it "only considers two atoms equal if identical" do
      a.should_not == b
    end
  end

  describe "the swap! method" do
    let(:v) { Rouge::Atom.new(456) }

    context "applying function (and any arguments) to the atom's value" do
      describe "first swap" do
        before { v.swap!(lambda {|n| n * 2}) }
        
        it { v.deref.should eq 912 }

        describe "second swap" do
          before { v.swap!(lambda {|n, m| [n / 2, m]}, 'quack') }
      
          it { v.deref.should eq [456, 'quack'] }
        end
      end
    end
  end
end

# vim: set sw=2 et cc=80:
