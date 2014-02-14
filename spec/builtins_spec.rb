# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Builtins do
  let(:ns) { Rouge::Namespace.new(:"user.spec").clear }
  let(:context) { Rouge::Context.new ns }

  let(:read) { lambda {|input|
    Rouge::Reader.new(ns, input).lex
  } }

  let(:compile) { lambda {|input|
    form = read.(input)
    Rouge::Compiler.compile(ns, Set.new, form)
  } }

  before { ns.refer Rouge::Namespace[:"rouge.builtin"] }

  describe "let" do
    describe "making local bindings" do
      it { context.readeval("(let [a 42] a)").should eq 42 }
      it { context.readeval("(let [a 1 a 2] a)").should eq 2 }
    end

    describe "destructuring" do
      before { context.set_here :"one-two", [1, 2] }
      it { context.readeval("(let [[a b] one-two] [a b])").should eq [1, 2] }

      before { context.set_here :"x3-y4l", {:x => 3, :y => [4]} }
      it { context.readeval("(let [{a :x [b] :y} x3-y4l] b)").
               should eq 4 }
      it { context.readeval("(let [{:keys [x]} x3-y4l] x)").should eq 3 }

      before { context.set_here :"one-two-three", [1, 2, 3] }
      it { context.readeval("(let [[a & b] one-two-three] [a b])").
               should eq [1, [2, 3]] }
      it { context.readeval("(let [[a & b :as f] one-two-three] [a b f])").
               should eq [1, [2, 3], [1, 2, 3]] }
    end

    describe "compilation by adding binding names to bindings" do
      context "flat" do
        before do
          Rouge::Compiler.should_receive(:compile).
            with(ns, kind_of(Set), anything) do |ns, lexicals, f|
              case f
                when Rouge::Symbol[:c] then lexicals.should eq Set[]
                when 2 then lexicals.should eq Set[:a]
                when 1 then lexicals.should eq Set[:a, :b]
              end
          end.exactly(3).times
        end

        it do
          Rouge::Builtins._compile_let(
            ns, Set.new,
            [Rouge::Symbol[:a], Rouge::Symbol[:c],
             Rouge::Symbol[:b], 2],
            1)
        end
      end

      context "nested" do
        before do
          Rouge::Compiler.should_receive(:compile).
            with(ns, kind_of(Set), anything) do |ns, lexicals, f|
              case f
                when [1, 2] then lexicals.should eq Set[]
                when 3 then lexicals.should eq Set[:a, :b]
                when 1 then lexicals.should eq Set[:a, :b, :c]
              end
          end.exactly(3).times
        end

        it do
          Rouge::Builtins._compile_let(
            ns, Set.new,
            [[Rouge::Symbol[:a], Rouge::Symbol[:b]], [1, 2],
             Rouge::Symbol[:c], 3],
            1)
        end
      end
    end
  end

  describe "context" do
    it "should return the calling context" do
      context.readeval("(context)").should be context
    end

    it "should have no special compile function" do
      Rouge::Builtins.should_not respond_to :_compile_context
    end
  end

  describe "quote" do
    it "should prevent evaluation" do
      context.readeval("(quote lmnop)").should eq ns.read 'lmnop'
    end

    it "should not compile the argument" do
      Rouge::Compiler.should_not_receive(:compile).
          with(ns, kind_of(Set), Rouge::Symbol[:z])

      Rouge::Builtins._compile_quote(
          ns, Set.new,
          Rouge::Symbol[:z])
    end
  end

  describe "fn" do
    describe "creating a new lambda function" do
      let(:l) { context.readeval('(fn [] "Mystik Spiral")') }

      it { l.should be_an_instance_of Proc }
      it { l.call.should eq "Mystik Spiral" }
      it { context.eval(Rouge::Seq::Cons[l]).should eq "Mystik Spiral" }
    end

    it "should create functions of correct arity" do
      expect {
        context.readeval('(fn [])').call(true)
      }.to raise_exception(
          ArgumentError, "wrong number of arguments (1 for 0)")

      expect {
        context.readeval('(fn [a b c])').call(:x, :y)
      }.to raise_exception(
          ArgumentError, "wrong number of arguments (2 for 3)")

      expect {
        context.readeval('(fn [& rest])').call()
        context.readeval('(fn [& rest])').call(1)#
        context.readeval('(fn [& rest])').call(1, 2, 3)
        context.readeval('(fn [& rest])').call(*(1..10000))
      }.to_not raise_exception
    end

    context "arity overloading" do

      it "should include a list of arities when compiled" do
        single_arity = "(fn [x] 1)"
        multi_arity  = "(fn ([] 0) ([_] 1))"
        compiled = compile.(single_arity)
        compile.(single_arity).to_a.should == [Rouge::Symbol[:fn],
                                               [Rouge::Symbol[:x]],
                                               1]
        compile.(multi_arity).to_a.should eq(
          [Rouge::Symbol[:fn],
           [[Rouge::Symbol[:fn], [], 0],
            [Rouge::Symbol[:fn], [Rouge::Symbol[:_]], 1]]])
      end

      it "should create functions with overloaded arity" do
        fn = <<-FN
        (fn
          ([] 0)
          ([a] 1)
          ([a b] 2)
          ([a b & c] :more))
        FN
        context.readeval(fn).call().should == 0
        context.readeval(fn).call(1).should == 1
        context.readeval(fn).call(1, 2).should == 2
        context.readeval(fn).call(1, 2, 3).should == :more
      end

      it "multi-arity functions should be order-agnostic" do
        fn = <<-FN
        (fn
          ([a b] 2)
          ([a] 1)
          ([a b & c] :more)
          ([] 0))
        FN
        context.readeval(fn).call().should == 0
        context.readeval(fn).call(1).should == 1
        context.readeval(fn).call(1, 2).should == 2
        context.readeval(fn).call(1, 2, 3).should == :more
      end

      xit "should handle block args"
    end

    describe "argument binding" do
      # TODO: refactor & break out individual assertions
      it "should bind place arguments correctly" do
        context.readeval('(fn [a] a)').call(:zzz).should eq :zzz
        context.readeval('(fn [a b] [a b])').
            call(:daria, :morgendorffer).
            should eq [:daria, :morgendorffer]
      end

      it "should bind rest arguments correctly" do
        context.readeval('(fn [y z & rest] [y z rest])').
            call("where", "is", "mordialloc", "gosh").
            should eq ns.read('["where" "is" ("mordialloc" "gosh")]')
      end

      describe "binding block arguments correctly" do
        let(:l) { lambda {} }

        it { context.readeval('(fn [a | b] [a b])').
             call("hello", &l).
             should eq ["hello", l] }
      end
    end

    describe "storing its own name" do
      let(:fn) { context.readeval('(fn lmnop [])') }

      it { fn.to_s.should eq :lmnop }
    end

    it "should compile with names bound" do
      Rouge::Compiler.should_receive(:compile).
          with(ns, kind_of(Set), [:xyzzy]) do |ns, lexicals, f|
        lexicals.should eq Set[:a, :rest, :block]
        [:xyzzy]
      end

      Rouge::Builtins._compile_fn(
          ns, Set.new,
          [Rouge::Symbol[:a],
           Rouge::Symbol[:&],
           Rouge::Symbol[:rest],
           Rouge::Symbol[:|],
           Rouge::Symbol[:block]],
          :xyzzy)
    end

    it "should use a new context per invocation" do
      context.readeval(<<-ROUGE).should eq :a
        (let [f (fn [x]
                  (if (.== x :a)
                    (do
                      (f :b)
                      x)
                    nil))]
          (f :a))
      ROUGE
    end
  end

  describe "def" do
    it "should create and intern a var" do
      context.readeval("(def barge)").
          should eq Rouge::Var.new(:"user.spec", :barge)
    end

    it "should always make a binding at the top of the namespace" do
      subcontext = Rouge::Context.new context
      subcontext.readeval("(def sarge :b)").
          should eq Rouge::Var.new(:"user.spec", :sarge, :b)
      context.readeval('sarge').should eq :b
    end

    it "should not compile the first argument" do
      Rouge::Compiler.should_not_receive(:compile).
          with(ns, kind_of(Set), Rouge::Symbol[:a])

      Rouge::Compiler.should_receive(:compile).
          with(ns, kind_of(Set), [Rouge::Symbol[:b]]) do |ns, lexicals, f|
        lexicals.should eq Set[:a]
      end

      Rouge::Builtins._compile_def(
          ns, Set.new,
          Rouge::Symbol[:a],
          Rouge::Symbol[:b])
    end
  end

  describe "if" do
    # TODO: refactor & break out individual assertions
    it "should execute one branch or the other" do
      a = double("a")
      b = double("b")
      a.should_receive(:call).with(any_args)
      b.should_not_receive(:call).with(any_args)
      subcontext = Rouge::Context.new context
      subcontext.set_here :a, a
      subcontext.set_here :b, b
      subcontext.readeval('(if true (a) (b))')
    end

    # TODO: refactor & break out individual assertions
    it "should not do anything in the case of a missing second branch" do
      a = double("a")
      a.should_not_receive(:call)
      subcontext = Rouge::Context.new context
      subcontext.set_here :a, a
      subcontext.readeval('(if false (a))')
    end

    it "should have no special compile function" do
      Rouge::Builtins.should_not respond_to :_compile_if
    end
  end

  describe "do" do
    it "should return nil with no arguments" do
      context.readeval('(do)').should eq nil
    end

    describe "evaluating and returning one argument" do
      let(:subcontext) { Rouge::Context.new context }

      before { subcontext.set_here :x, lambda {4} }

      it { subcontext.readeval('(do (x))').should eq 4 }
    end

    # TODO: refactor & break out individual assertions
    it "should evaluate multiple arguments and return the last value" do
      a = double("a")
      a.should_receive(:call)
      subcontext = Rouge::Context.new context
      subcontext.set_here :a, a
      subcontext.set_here :b, lambda {7}
      subcontext.readeval('(do (a) (b))').should eq 7
    end

    it "should compile and do the right thing with multiple forms" do
      context.readeval(<<-ROUGE).should eq 1
        (do
          (def o (ruby/Rouge.Atom. 1))
          (.deref o))
      ROUGE
    end

    it "should compile straight-through" do
      Rouge::Builtins._compile_do(ns, Set.new, :x, Rouge::Symbol[:y]).
          should eq [Rouge::Symbol[:do], :x, Rouge::Symbol[:y]]
    end
  end

  describe "ns" do
    before { Rouge::Namespace.destroy :"user.spec2" }

    it "should create and use a new context pointing at a given ns" do
      context.readeval('(do (ns user.spec2) (def nope 8))')
      Rouge[:"user.spec2"][:nope].deref.should eq 8
      expect {
        context[:nope]
      }.to raise_exception Rouge::Namespace::VarNotFoundError
    end

    it "should support the :use option" do
      context.readeval(<<-ROUGE).should eq "<3"
          (do
            (ns user.spec2)
            (def love "<3")

            (ns user.spec3
              (:use user.spec2))
            love)
      ROUGE
    end

    describe ":require" do
      it "should support the option" do
        Object.should_receive(:require).with("blah")
        context.readeval(<<-ROUGE)
            (ns user.spec2
              (:require blah))
        ROUGE
      end

      it "should support it with :as" do
        File.should_receive(:read).with("blah.rg").and_return("")
        context.readeval(<<-ROUGE)
            (ns user.spec2
              (:require [blah :as x]))
        ROUGE
        Rouge::Namespace[:x].should be Rouge::Namespace[:blah]
      end

      it ":as should not reload it" do
        File.should_not_receive(:read).with("moop.rg")
        context.readeval(<<-ROUGE)
            (do
              (ns moop)
              (ns user.spec2
                (:require [moop :as y])))
        ROUGE
        Rouge::Namespace[:y].should be Rouge::Namespace[:moop]
      end

      it "should refer rouge.core and ruby" do
        context.readeval "(ns toast)"
        Rouge[:toast].refers.should include(Rouge[:"rouge.core"])
        Rouge[:toast].refers.should include(Rouge[:"ruby"])
      end
    end

    it "should compile without compiling any of its components" do
      Rouge::Compiler.should_not_receive(:compile)
      Rouge::Builtins._compile_ns(ns, Set.new, Rouge::Symbol[:non_extant])
    end
  end

  describe "defmacro" do
    let(:v) { context.readeval("(defmacro a [] 'b)") }

    it { v.should be_an_instance_of Rouge::Var }
    it { v.ns.should eq :"user.spec" }
    it { v.name.should eq :a }

    describe "evaluation in the defining context" do
      it { expect { context.readeval("(defmacro a [] b)")
                  }.to raise_exception Rouge::Namespace::VarNotFoundError }

      describe "after readeval (def ...)" do
        before { context.readeval("(def b 'c)") }

      it { expect { context.readeval("(defmacro a [] b)")
                  }.to_not raise_exception }
      end
    end

    it "should expand in the calling context" do
      context.readeval("(def b 'c)")
      context.readeval("(defmacro zoom [] b)")

      expect {
        context.readeval("(zoom)")
      }.to raise_exception Rouge::Namespace::VarNotFoundError

      context.readeval("(let [c 9] (zoom))").should eq 9
    end

    it "should support the multiple argument list form" do
      ns.set_here :vector, context.readeval(<<-ROUGE)
        (fn [& r] r)
      ROUGE

      context.readeval(<<-ROUGE)
        (defmacro m
          ([a] (vector 'vector ''a (vector 'quote a)))
          ([b c] (vector 'vector ''b (vector 'quote b) (vector 'quote c))))
      ROUGE

      context.readeval("(m x)").should eq ns.read("(a x)")
      context.readeval("(m x y)").should eq ns.read("(b x y)")
    end

    describe "compilation" do
      it "should compile single-arg form with names bound" do
        Rouge::Compiler.should_receive(:compile).
            with(ns, kind_of(Set), [:foo]) do |ns, lexicals, f|
          lexicals.should eq Set[:quux, :rest, :block]
          [:foo]
        end

        Rouge::Builtins._compile_defmacro(
            ns, Set.new,
            Rouge::Symbol[:barge],
            [Rouge::Symbol[:quux],
             Rouge::Symbol[:&],
             Rouge::Symbol[:rest],
             Rouge::Symbol[:|],
             Rouge::Symbol[:block]],
            :foo)
      end

      it "should compile multi-arg form with names bound" do
        # TODO: consider breaking out these two test assertion
        #   blocks into their own context: they actually both fail
        #   in isolation but those failures are masked because
        #   the "Rouge::Builtins._compile_defmacro" test passes,
        #   and that last evaluation to 'true' gets passed as the
        #   return value to the enclosing 'it' method. Try it: change
        #   the order around, and you'll see the failure. REW
        #
        #Rouge::Compiler.should_receive(:compile).
        #    with(ns, kind_of(Set), [:a1]) do |n, lexicals, f|
        #  lexicals.should eq Set[:f]
        #  [:a1]
        #end
        #
        #Rouge::Compiler.should_receive(:compile).
        #    with(ns, kind_of(Set), [:a2]) do |n, lexicals, f|
        #  lexicals.should eq Set[:g]
        #  [:a2]
        #end
        #
        Rouge::Builtins._compile_defmacro(
            ns, Set.new,
            Rouge::Symbol[:barge],
            Rouge::Seq::Cons[[Rouge::Symbol[:f]], :a1],
            Rouge::Seq::Cons[[Rouge::Symbol[:g]], :a2])
      end
    end

    describe "storing its own name" do
      before { context.readeval('(defmacro lmnop [])') }

      it { context[:lmnop].deref.to_s.should eq :"user.spec/lmnop" }
    end
  end

  describe "apply" do
    let(:a) { lambda {|*args| args} }
    let(:subcontext) { Rouge::Context.new context }

    before { subcontext.set_here :a, a }

    describe "calling a function with the argument list" do
      it { subcontext.readeval("(apply a [1 2 3])").should eq [1, 2, 3] }
      it { subcontext.readeval("(apply a '(1 2 3))").should eq [1, 2, 3] }
    end

    describe "calling a function with intermediate arguments" do
      it { subcontext.readeval("(apply a 8 9 [1 2 3])").should eq [8, 9, 1, 2, 3] }
      it { subcontext.readeval("(apply a 8 9 '(1 2 3))").should eq [8, 9, 1, 2, 3] }
    end

    it "should have no special compile function" do
      Rouge::Builtins.should_not respond_to :_compile_apply
    end
  end

  describe "var" do
    it "should return the var for a given symbol" do
      ns.set_here :x, 42
      context.readeval("(var x)").
          should eq Rouge::Var.new(:"user.spec", :x, 42)
    end

    it "should compile directly to the var" do
      ns.set_here :x, 80
      Rouge::Builtins._compile_var(ns, Set.new, Rouge::Symbol[:x]).
          should eq [Rouge::Symbol[:quote],
                     Rouge::Var.new(:"user.spec", :x, 80)]
    end
  end

  describe "throw" do
    it "should raise the given throwable as an exception" do
      expect {
        context.readeval('(throw (ruby/RuntimeError. "boo"))')
      }.to raise_exception RuntimeError, 'boo'
    end

    it "should have no special compile function" do
      Rouge::Builtins.should_not respond_to :_compile_throw
    end
  end

  describe "try" do
    it "should catch exceptions mentioned in the catch clause" do
      context.readeval(<<-ROUGE).should eq :eofe
        (try
          (throw (ruby/EOFError. "bad"))
          :baa
          (catch ruby/EOFError _ :eofe))
      ROUGE
    end

    it "should catch only the desired exception" do
      context.readeval(<<-ROUGE).should eq :nie
        (try
          (throw (ruby/NotImplementedError. "bro"))
          :baa
          (catch ruby/EOFError _ :eofe)
          (catch ruby/NotImplementedError _ :nie))
      ROUGE
    end

    it "should actually catch exceptions" do
      context.readeval(<<-ROUGE).should eq 3
        (try
          {:a 1 :b 2}
          (throw (ruby/Exception.))
          (catch ruby/Exception _ 3))
      ROUGE
    end

    it "should let other exceptions fall through" do
      expect {
        context.readeval(<<-ROUGE)
          (try
            (throw (ruby/Exception. "kwok"))
            :baa
            (catch ruby/EOFError _ :eofe)
            (catch ruby/NotImplementedError _ :nie))
        ROUGE
      }.to raise_exception Exception, 'kwok'
    end

    it "should work despite catch or finally being interned elsewhere" do
      context.readeval(<<-ROUGE).should eq :baa
        (try
          :baa
          (b/catch ruby/EOFError _ :eofe)
          (a/catch ruby/NotImplementedError _ :nie))
      ROUGE
    end

    it "should return the block's value if no exception was raised" do
      context.readeval(<<-ROUGE).should eq :baa
        (try
          :baa
          (catch ruby/EOFError _ :eofe)
          (catch ruby/NotImplementedError _ :nie))
      ROUGE
    end

    it "should evaluate the finally expressions without returning them" do
      ns.set_here :m, Rouge::Atom.new(1)

      context.readeval(<<-ROUGE).should eq :baa
        (try
          :baa
          (catch ruby/NotImplementedError _ :nie)
          (finally
            (.swap! m #(.+ 1 %))))
      ROUGE

      context[:m].deref.deref.should eq 2

      ns.set_here :o, Rouge::Atom.new(1)

      expect {
        context.readeval(<<-ROUGE).should eq :baa
          (try
            (throw (ruby/ArgumentError. "fire"))
            :baa
            (catch ruby/NotImplementedError _ :nie)
            (finally
              (.swap! o #(.+ 1 %))))
        ROUGE
      }.to raise_exception ArgumentError, 'fire'

      context[:o].deref.deref.should eq 2
    end

    it "should bind the exception expressions" do
      context.readeval(<<-ROUGE).should be_an_instance_of(NotImplementedError)
        (try
          (throw (ruby/NotImplementedError. "wat"))
          (catch ruby/NotImplementedError e
            e))
      ROUGE
    end

    describe "compilation" do
      let(:compile) { lambda {|rouge, lexicals=[]|
          Rouge::Builtins._compile_try(
            ns, Set[*lexicals],
            *Rouge::Reader.new(ns, rouge).lex.to_a) } }

      it "should compile the main body" do
        expect {
          compile.call("(a)")
        }.to raise_exception Rouge::Namespace::VarNotFoundError

        expect {
          compile.call("(a)", [:a])
        }.to_not raise_exception
      end

      it "should compile catch clauses with bindings" do
        expect {
          compile.call("(a (catch ruby/NotImplementedError b c))", [:a])
        }.to raise_exception Rouge::Namespace::VarNotFoundError

        expect {
          compile.call("(a (catch ruby/NotImplementedError b b))", [:a])
        }.to_not raise_exception
      end
    end
  end

  describe "destructure" do
    it "should return a hash of symbols to assigned values" do
      context.readeval("(destructure [a b c] [1 2 3])").to_s.
          should eq({Rouge::Symbol[:a] => 1,
                     Rouge::Symbol[:b] => 2,
                     Rouge::Symbol[:c] => 3}.to_s)
    end

    it "should assign rest arguments" do
      context.readeval("(destructure [a & b] [1 2 3])").to_s.
          should eq({Rouge::Symbol[:a] => 1,
                     Rouge::Symbol[:b] => Rouge::Seq::Cons[2, 3]}.to_s)
    end

    it "should destructure seqs" do
      context.readeval("(destructure [[a b] c] [[1 2] 3])").to_s.
          should eq({Rouge::Symbol[:a] => 1,
                     Rouge::Symbol[:b] => 2,
                     Rouge::Symbol[:c] => 3}.to_s)
    end

    it "should destructure rests in nested seqs" do
      context.readeval("(destructure [a [b & c]] [1 [2 3 4]])").to_s.
          should eq({Rouge::Symbol[:a] => 1,
                     Rouge::Symbol[:b] => 2,
                     Rouge::Symbol[:c] => Rouge::Seq::Cons[3, 4]}.to_s)
    end

    context "destructuring blocks" do
      let(:x) { lambda {} }

      before { context.set_here :x, x }

      it { context.readeval("(destructure [a | b] [1 | x])").to_s.
             should eq({Rouge::Symbol[:a] => 1,
                        Rouge::Symbol[:b] => x}.to_s) }
    end

    it { context.readeval(
             "(destructure {the-x :x the-y :y} {:x 5 :y 7})").to_s.
             should eq({Rouge::Symbol[:"the-x"] => 5,
                        Rouge::Symbol[:"the-y"] => 7}.to_s) }

    it { context.readeval(
             "(destructure [x & more :as full-list] [1 2 3])").to_s.
             should eq(
               {Rouge::Symbol[:"x"] => 1,
                Rouge::Symbol[:"more"] => Rouge::Seq::Cons[2, 3],
                Rouge::Symbol[:"full-list"] => Rouge::Seq::Cons[1, 2, 3]
               }.to_s) }

    it { context.readeval(
             "(destructure {:keys [x y]} {:x 5 :y 7})").to_s.
             should eq({Rouge::Symbol[:x] => 5,
                        Rouge::Symbol[:y] => 7}.to_s) }

    describe "compiling the value part" do
      it { expect {
             Rouge::Builtins._compile_destructure(
                 ns, Set.new, Rouge::Symbol[:z], Rouge::Symbol[:z])
           }.to raise_exception }

      it { expect {
             Rouge::Builtins._compile_destructure(
                 ns, Set[:y], Rouge::Symbol[:z], Rouge::Symbol[:y])
           }.to_not raise_exception }
    end

    describe "vigorous complaints about letting qualified names" do
      it { expect { context.readeval("(destructure [user.spec/x] [1])")
                  }.to raise_exception Rouge::Context::BadBindingError }
    end

    describe "not forcing what needn't be forced" do
      it { Rouge::Builtins.destructure(
               context,
               [Rouge::Symbol[:a], Rouge::Symbol[:&], Rouge::Symbol[:b]],
               Rouge::Seq::Lazy.new(lambda do
                 Rouge::Seq::Cons.new(
                   1,
                   Rouge::Seq::Lazy.new(lambda do
                     Rouge::Seq::Cons.new(
                       2,
                       Rouge::Seq::Lazy.new(lambda do
                         raise "shouldn't be forced"
                       end))
                   end))
               end)) }
    end
  end
end

# vim: set sw=2 et cc=80:
