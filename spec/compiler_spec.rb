# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Compiler do
  before do
    @ns = Rouge[:"user.spec"].clear
    @ns.refer Rouge[:"rouge.builtin"]

    @read = lambda do |input|
      Rouge::Reader.new(@ns, input).lex
    end

    @compile = lambda do |input|
      form = @read.call(input)
      Rouge::Compiler.compile(@ns, Set.new, form)
    end
  end

  describe "lexical lookup" do
    it "should compile with respect to locals" do
      lambda {
        @compile.call("(fn [] a)")
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)

      lambda {
        @compile.call("q")
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)

      lambda {
        @compile.call("(let [x 8] x)").
            should eq @read.call("(let [x 8] x)")
      }.should_not raise_exception

      lambda {
        @compile.call("(let [x 8] y)")
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)

      lambda {
        @compile.call("(let [x 8] ((fn [& b] (b)) | [e] e))")
      }.should_not raise_exception

      lambda {
        @compile.call("(let [x 8] ((fn [& b] (b)) | [e] f))")
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)
    end
  end

  describe "macro behaviour" do
    it "should execute macro calls when compiling" do
      @ns.set_here :thingy, Rouge::Macro[lambda {|f|
        Rouge::Seq::Cons[Rouge::Symbol[:list], *f.to_a]
      }]
      @compile.call("(let [list 'thing] (thingy (1 2 3)))").
          should eq @read.call("(let [list 'thing] (list 1 2 3))")
    end
  end

  describe "symbol lookup" do
    it "should compile X. symbols to procs which call X.new" do
      x = double("<class>")
      x.stub(:new => nil)

      @ns.set_here :x, x
      x_new = @compile.call("x.")
      x_new.should be_an_instance_of Rouge::Compiler::Resolved

      x.should_receive(:new).with(1, :z)
      x_new.res.call(1, :z)
    end

    it "should find the var in our namespace for an unqualified symbol" do
      @ns.set_here :tiffany, "wha?"
      @compile.call("tiffany").res.
          should eq Rouge::Var.new(:"user.spec", :tiffany, "wha?")
    end

    it "should find the var in a referred ns for an unqualified symbol" do
      v = @compile.call("def").res
      v.should be_an_instance_of(Rouge::Var)
      v.ns.should eq :"rouge.builtin"
      v.name.should eq :def
      v.deref.should be_an_instance_of(Rouge::Builtin)
    end

    it "should find the var in any namespace for a qualified symbol" do
      v = @compile.call("ruby/Kernel").res
      v.should be_an_instance_of(Rouge::Var)
      v.ns.should eq :ruby
      v.name.should eq :Kernel
      v.deref.should eq Kernel
    end

    it "should find the method for a new class instantiation" do
      m = @compile.call("ruby/String.").res
      m.should be_an_instance_of Method
      m.receiver.should eq String
      m.name.should eq :new
    end
  end

  describe "sub-compilation behaviour" do
    it "should compile Arrays and Hashes" do
      lambda {
        @compile.call("[a]")
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)

      @ns.set_here :a, :a
      lambda {
        @compile.call("[a]")
      }.should_not raise_exception

      lambda {
        @compile.call("{b c}")
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)

      @ns.set_here :b, :b
      lambda {
        @compile.call("{b c}")
      }.should raise_exception(Rouge::Namespace::VarNotFoundError)

      @ns.set_here :c, :c
      lambda {
        @compile.call("{b c}")
      }.should_not raise_exception
    end

    it "should compile inline blocks to fns" do
      @compile.call("(let [a 'thing] (a | [b] b))").
          should eq @read.call("(let [a 'thing] (a | (fn [b] b)))")
    end
  end
end

# vim: set sw=2 et cc=80:
