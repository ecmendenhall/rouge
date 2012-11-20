# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Atom do
  describe ".new" do
    let(:v) { Rouge::Atom.new(:snorlax) }
    it { v.deref.should eq :snorlax }
  end

  describe "#==" do
    let(:a) { Rouge::Atom.new(:raichu) }
    let(:b) { Rouge::Atom.new(:raichu) }

    it { a.should_not == b }
  end

  describe "#swap!" do
    let(:v) { Rouge::Atom.new(456) }

    context "first swap" do
      before { v.swap!(lambda {|n| n * 2}) }
      it { v.deref.should eq 912 }

      context "second swap" do
        before { v.swap!(lambda {|n, m| [n / 2, m]}, 'quack') }
        it { v.deref.should eq [456, 'quack'] }
      end
    end
  end

  describe "#reset!" do
    let(:v) { Rouge::Atom.new(999) }
    before { v.reset!(:lol) }
    it { v.deref.should eq :lol }
  end
end

# vim: set sw=2 et cc=80:
