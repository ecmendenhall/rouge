# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Namespace do
  describe "the [] method" do
    it "should vivify non-extant namespaces" do
      Rouge::Namespace.exists?(:vivify_test).should eq false
      Rouge::Namespace[:vivify_test].should be_an_instance_of Rouge::Namespace
      Rouge::Namespace.exists?(:vivify_test).should eq true
    end
  end

  describe "the Rouge[] shortcut" do
    it "should directly call the [] method" do
      Rouge::Namespace.should_receive(:[]).with(:trazzle)
      Rouge[:trazzle]
    end
  end

  describe "the set_here method" do
    it "should create a var for the name, assigning the root to the value" do
      w = Rouge::Namespace.new :w
      w.set_here :waldorf, "Yes!"
      w[:waldorf].should eq Rouge::Var.new(:w, :waldorf, "Yes!")
    end
  end

  describe "the intern method" do
    it "should create an unbound var for the name if it doesn't exist" do
      m = Rouge::Namespace.new :m
      m.intern :connor
      m[:connor].should eq Rouge::Var.new(:m, :connor)
    end

    it "should do nothing if the var already exists" do
      q = Rouge::Namespace.new :q
      q.set_here :matthias, 50
      q.intern :matthias
      q[:matthias].should eq Rouge::Var.new(:q, :matthias, 50)
    end
  end

  describe "the refer method" do
    it "should cause items in one namespace to be locatable from the other" do
      abc = Rouge::Namespace.new :abc
      xyz = Rouge::Namespace.new :xyz

      xyz.refer abc

      abc.set_here :hello, :wow
      xyz[:hello].deref.should eq :wow
    end

    it "may not be used to refer namespaces to themselves" do
      lambda {
        Rouge[:user].refer Rouge[:user]
      }.should raise_exception(Rouge::Namespace::RecursiveNamespaceError)
    end
  end

  describe "the destroy method" do
    it "should obliterate a namespace" do
      Rouge[:"user.spec2"].set_here :nope, :ok
      Rouge::Namespace.destroy :"user.spec2"
      lambda {
        Rouge[:"user.spec2"][:nope]
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)
    end
  end

  describe "the rouge.builtin namespace" do
    before do
      @ns = Rouge[:"rouge.builtin"]
    end

    it "should contain elements from Rouge::Builtins" do
      @ns[:let].deref.should be_an_instance_of Rouge::Builtin
      @ns[:quote].deref.should be_an_instance_of Rouge::Builtin
    end

    it "should not find objects from ruby" do
      lambda {
        @ns[:Float]
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)
      lambda {
        @ns[:String]
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)
    end

    it "should have a name" do
      @ns.name.should eq :"rouge.builtin"
    end
  end

  describe "the ruby namespace" do
    before do
      @ns = Rouge::Namespace[:ruby]
    end

    it "should contain elements from Kernel" do
      @ns[:Hash].should eq Rouge::Var.new(:ruby, :Hash, Hash)
      @ns[:Fixnum].should eq Rouge::Var.new(:ruby, :Fixnum, Fixnum)
    end

    it "should contain global variables" do
      @ns[:"$LOAD_PATH"].
          should eq Rouge::Var.new(:ruby, :$LOAD_PATH, $LOAD_PATH)
    end

    it "should have a name" do
      @ns.name.should eq :ruby
    end
  end

  describe "the read method" do
    it "should read input in this namespace" do
      Rouge::Namespace[:xyz].read("`ham").
          should eq Rouge::Seq::Cons[Rouge::Symbol[:quote],
                                Rouge::Symbol[:"xyz/ham"]]
    end
  end
end

# vim: set sw=2 et cc=80:
