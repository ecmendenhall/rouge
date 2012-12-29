# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Symbol do
  describe "lookup" do
    it { Rouge::Symbol[:true].should be true }
    it { Rouge::Symbol[:false].should be false }
    it { Rouge::Symbol[:nil].should be nil }
  end

  describe ".[]" do
    it { Rouge::Symbol[:a].should_not be Rouge::Symbol[:a] }
    # but:
    it { Rouge::Symbol[:a].should eq Rouge::Symbol[:a] }
  end

  describe "#ns, #name" do
    it { Rouge::Symbol[:abc].ns.should be_nil }
    it { Rouge::Symbol[:abc].name.should eq :abc }
    it { Rouge::Symbol[:"abc/def"].ns.should eq :abc }
    it { Rouge::Symbol[:"abc/def"].name.should eq :def }
    it { Rouge::Symbol[:/].ns.should be_nil }
    it { Rouge::Symbol[:/].name.should eq :/ }
    it { Rouge::Symbol[:"rouge.core//"].ns.should eq :"rouge.core" }
    it { Rouge::Symbol[:"rouge.core//"].name.should eq :/ }
  end

  describe "#to_sym" do
    it { Rouge::Symbol[:boo].to_sym.should eq :boo }
    it { Rouge::Symbol[:"what/nice"].to_sym.should eq :"what/nice" }
  end

  describe "#to_s" do
    it { Rouge::Symbol[:"breakfast"].to_s.should eq "breakfast" }
    it { Rouge::Symbol[:"breakfast/toast"].to_s.should eq "breakfast/toast" }
  end
end

# vim: set sw=2 et cc=80:
