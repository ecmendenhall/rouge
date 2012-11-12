# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Metadata do
  before do
    @class = Class.new do
      include Rouge::Metadata
    end
  end

  describe "the metadata accessors" do
    it "should be present on class instances" do
      @class.new.should respond_to(:meta).with(0).arguments
      @class.new.should respond_to(:meta=).with(1).argument
    end

    it "should default to nil" do
      @class.new.meta.should be_nil
    end

    it "should return the new value when set" do
      i = @class.new
      i.meta = {:x => 4}
      i.meta.to_s.should eq({:x => 4}.to_s)
    end

    it "should not allow being set to anything other than a Hash or nil" do
      lambda {
        @class.new.meta = {:a => 1}
        @class.new.meta = {}
        @class.new.meta = {1 => 2, 3 => 4, 5 => {}}
        @class.new.meta = nil
      }.should_not raise_exception

      lambda {
        @class.new.meta = 4
      }.should raise_exception(Rouge::Metadata::InvalidMetadataError)

      lambda {
        @class.new.meta = true
      }.should raise_exception(Rouge::Metadata::InvalidMetadataError)

      lambda {
        @class.new.meta = Rouge::Symbol[:blah]
      }.should raise_exception(Rouge::Metadata::InvalidMetadataError)

      lambda {
        @class.new.meta = []
      }.should raise_exception(Rouge::Metadata::InvalidMetadataError)

      lambda {
        @class.new.meta = Rouge::Seq::Cons["what"]
      }.should raise_exception(Rouge::Metadata::InvalidMetadataError)
    end
  end
end

# vim: set sw=2 et cc=80:
