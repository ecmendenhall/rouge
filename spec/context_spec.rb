# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Context do
  before do
    @a = Rouge::Context.new nil
    @ab = Rouge::Context.new @a
    @abb = Rouge::Context.new @ab
    @ac = Rouge::Context.new @a
    @a.set_here :root, 42
    @a.set_here :bah, (@bah = Object.new)
    @ab.set_here :root, 80
    @ac.set_here :non, 50

    @spec = Rouge::Namespace[:"user.spec"].clear
    @spec.refer Rouge::Namespace[:"rouge.builtin"]
    @spec.set_here :tiffany, "wha?"
    @in_spec = Rouge::Context.new @spec
    @in_spec.set_here :blah, "code code"

    @ns = Rouge[:"rouge.builtin"]
    @context = Rouge::Context.new @ns
    @nested_context = Rouge::Context.new @context
  end

  describe "the [] method" do
    it "should get the closest binding" do
      @a[:root].should eq 42
      @ab[:root].should eq 80
      @abb[:root].should eq 80
      @ac[:root].should eq 42
      # var, because it's from a namespace
      @context[:let].deref.should be_an_instance_of Rouge::Builtin
    end

    it "should raise an exception if a binding is not found" do
      lambda {
        @a[:non]
      }.should raise_exception(Rouge::Context::BindingNotFoundError)
    end
  end

  describe "the ns method" do
    it "should get the namespace of a context that has one" do
      @context.ns.should eq Rouge::Namespace[:"rouge.builtin"]
    end

    it "should get the namespace of a nested context that has one" do
      @nested_context.ns.should eq Rouge::Namespace[:"rouge.builtin"]
    end

    it "should return nil if a context has none" do
      @a.ns.should eq nil
      @ab.ns.should eq nil
    end
  end

  describe "the set_here method" do
    it "should set in the given context, shadowing outer bindings" do
      @ac.set_here :root, 90
      @ac[:root].should eq 90
      @a[:root].should eq 42
    end
  end

  describe "the set_lexical method" do
    it "should set in the closest context" do
      @abb.set_lexical :root, 777
      @abb[:root].should eq 777
      @ab[:root].should eq 777
      @a[:root].should eq 42
    end

    it "should raise an exception if a closest binding is not found" do
      lambda {
        @abb.set_lexical :non, 10
      }.should raise_exception(Rouge::Context::BindingNotFoundError)
    end
  end

  describe "the eval method" do
    it "should eval a form in this context without processing the backtrace" do
      @a.eval([5]).should eq [5]

      begin
        @a.eval(Rouge::Seq::Cons[Rouge::Symbol[:blorgh]])
        raise "failed!"
      rescue Rouge::Context::BindingNotFoundError => e
        e.backtrace.any? {|line| line =~ /^\(rouge\):/}.should be_false
      end
    end
  end

  describe "the readeval method" do
    it "should post-process the backtrace" do
      return pending

      Rouge.boot!
      context = Rouge::Context.new Rouge[:user]

      ex = nil
      begin
        context.readeval(<<-ROUGE)
          (do
            (defn z [] (throw (RuntimeError. "boo")))
            (defn y [] (z))
            (defn x [] (y))
            (x))
        ROUGE
      rescue RuntimeError => e
        ex = e
      end

      ex.should_not be_nil
      ex.backtrace[0..3].
          should eq ["(rouge):?:rouge.builtin/throw",
                     "(rouge):?:user/z",
                     "(rouge):?:user/y",
                     "(rouge):?:user/x"]
    end

    it "should compile with lexicals from the found context" do
      context = Rouge::Context.new nil
      context.set_here :quux, 4
      context.set_here :bar, 5

      Rouge::Compiler.should_receive(:compile).
          with(context.ns, kind_of(Set), true) do |ns, lexicals, f|
        lexicals.should eq Set[:quux, :bar]
      end

      context.readeval("true")
    end
  end

  describe "the locate method" do
    it "should find the method for a new call to a lexical" do
      arg = double("<arg>")
      m = @a.locate(Rouge::Symbol[:"bah."])
      m.should be_an_instance_of Proc
      @bah.should_receive(:new).with(arg)
      m.call(arg)
    end
  end

  it "should evaluate quotations to their unquoted form" do
    @context.readeval("'x").should eq @ns.read("x")
    @context.readeval("'':zzy").should eq @ns.read("':zzy")
  end

  describe "symbols" do
    it "should evaluate symbols to the object within their context" do
      @context.set_here :vitamin_b, "vegemite"
      @context.readeval("vitamin_b").should eq "vegemite"

      subcontext = Rouge::Context.new @context
      subcontext.set_here :joy, [:yes]
      subcontext.set_here :/, "wah"
      subcontext.readeval("joy").should eq [:yes]
      subcontext.readeval("vitamin_b").should eq "vegemite"
      subcontext.readeval("/").should eq "wah"
    end

    it "should evaluate symbols in other namespaces" do
      @context.readeval("ruby/Object").should eq Object
      @context.readeval("ruby/Exception").should eq Exception
    end

    it "should evaluate nested objects" do
      @context.readeval("ruby/Rouge.Context").should eq Rouge::Context
      @context.readeval("ruby/Errno.EAGAIN").should eq Errno::EAGAIN
    end
  end

  it "should evaluate other things to themselves" do
    @context.eval(4).should eq 4
    @context.eval("bleep bloop").should eq "bleep bloop"
    @context.eval(:"nom it").should eq :"nom it"
    @context.readeval("{:a :b, 1 2}").to_s.should eq({:a => :b, 1 => 2}.to_s)

    l = lambda {}
    @context.eval(l).should eq l

    o = Object.new
    @context.eval(o).should eq o
  end

  it "should evaluate hash and vector arguments" do
    @context.readeval("{\"z\" 92, 'x ''5}").to_s.
        should eq @ns.read("{\"z\" 92, x '5}").to_s

    subcontext = Rouge::Context.new @context
    subcontext.set_here :lolwut, "off"
    subcontext.readeval("{lolwut [lolwut]}").
        should eq @ns.read('{"off" ["off"]}')
  end

  describe "function calls" do
    it "should evaluate function calls" do
      subcontext = Rouge::Context.new @context
      subcontext.set_here :f, lambda {|x| "hello #{x}"}
      subcontext.readeval('(f "world")').should eq "hello world"
    end

    it "should evaluate macro calls" do
      macro = Rouge::Macro[lambda {|n, *body|
        Rouge::Seq::Cons[Rouge::Symbol[:let], Rouge::Seq::Cons[n, "example"].freeze,
          *body]
      }]

      @ns.set_here :macro, macro

      subcontext = Rouge::Context.new @context
      subcontext.set_here :f, lambda {|x,y| x + y}
      subcontext.readeval('(macro bar (f bar bar))').should eq "exampleexample"
    end

    it "should evaluate calls with inline blocks and block binds" do
      @context.readeval('((fn [a | b] (b a)) 42 | [e] (./ e 2))').should eq 21
    end

    describe "Ruby interop" do
      describe "new object creation" do
        it "should call X.new with (X.)" do
          klass = double("klass")
          klass.should_receive(:new).with(@ns.read('a')).and_return(:b)

          subcontext = Rouge::Context.new @context
          subcontext.set_here :klass, klass
          subcontext.readeval("(klass. 'a)").should eq :b
        end
      end

      describe "generic method calls" do
        it "should call x.y(:z) with (.y x 'z)" do
          x = double("x")
          x.should_receive(:y).with(@ns.read('z')).and_return(:tada)

          subcontext = Rouge::Context.new @context
          subcontext.set_here :x, x
          subcontext.readeval("(.y x 'z)").should eq :tada
        end

        it "should call q.r(:s, &t) with (.r q 's | t)" do
          q = double("q")
          t = lambda {}
          q.should_receive(:r).with(@ns.read('s'), &t).and_return(:bop)

          subcontext = Rouge::Context.new @context
          subcontext.set_here :q, q
          subcontext.set_here :t, t
          subcontext.readeval("(.r q 's | t)").should eq :bop
        end

        it "should call a.b(:c) {|d| d + 1} with (.b a 'c | [d] (.+ d 1))" do
          a = double("a")
          a.should_receive(:b) do |c, &b|
            c.should eq @ns.read('c')
            b.call(1).should eq 2
            b.call(2).should eq 3
            b.call(3).should eq 4
            :ok
          end

          subcontext = Rouge::Context.new @context
          subcontext.set_here :a, a
          subcontext.readeval("(.b a 'c | [d] (.+ d 1))").should eq :ok
        end
      end
    end
  end
end

# vim: set sw=2 et cc=80:
