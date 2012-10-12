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
end

describe Rouge::Seq do
  describe "the seq method" do
    #it { Rouge::Seq.seq(
  end
end

# vim: set sw=2 et cc=80:
