# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Compiler do
  let(:ns) { Rouge[:"user.spec"].clear.refer(Rouge[:"rouge.builtin"]) }

  let(:read) { lambda {|input|
    Rouge::Reader.new(ns, input).lex
  } }

  let(:compile) { lambda {|input|
    form = read.(input)
    Rouge::Compiler.compile(ns, Set.new, form)
  } }

  describe "lexical lookup" do
    it { expect { compile.("(fn [] a)")
                }.to raise_exception(Rouge::Namespace::VarNotFoundError) }

    it { expect { compile.("q")
                }.to raise_exception(Rouge::Namespace::VarNotFoundError) }

    it { expect { compile.("(let [x 8] x)").should eq read.("(let [x 8] x)")
                }.to_not raise_exception }

    it { expect { compile.("(let [x 8] y)")
                }.to raise_exception(Rouge::Namespace::VarNotFoundError) }

    it { expect { compile.("(let [x 8] ((fn [& b] (b)) | [e] e))")
                }.to_not raise_exception }

    it { expect { compile.("(let [x 8] ((fn [& b] (b)) | [e] f))")
                }.to raise_exception(Rouge::Namespace::VarNotFoundError) }
  end

  describe "macro behaviour" do
    before do
      ns.set_here(:thingy, Rouge::Macro[lambda {|f|
        Rouge::Seq::Cons[Rouge::Symbol[:list], *f.to_a]
      }])
    end

    it do
      compile.("(let [list 'thing] (thingy (1 2 3)))").
          should eq read.("(let [list 'thing] (list 1 2 3))")
    end
  end

  describe "symbol lookup" do
    it do
      x = double("class")
      x.stub(:new => nil)

      ns.set_here(:x, x)
      x_new = compile.("x.")
      x_new.should be_an_instance_of Rouge::Compiler::Resolved

      x.should_receive(:new).with(1, :z)
      x_new.res.call(1, :z)
    end

    context "var in context ns" do
      before { ns.set_here(:tiffany, "wha?") }
      it { compile.("tiffany").res.
             should eq Rouge::Var.new(:"user.spec", :tiffany, "wha?") }
    end

    context "vars in referred ns" do
      subject { compile.("def").res }
      it { should be_an_instance_of Rouge::Var }
      its(:ns) { should eq :"rouge.builtin" }
      its(:name) { should eq :def }
      its(:deref) { should be_an_instance_of(Rouge::Builtin) }
    end

    context "var in qualified ns" do
      subject { compile.("ruby/Kernel").res }
      it { should be_an_instance_of Rouge::Var }
      its(:ns) { should eq :ruby }
      its(:name) { should eq :Kernel }
      its(:deref) { should eq Kernel }
    end

    context "class instantiation" do
      subject { compile.("ruby/String.").res }
      it { should be_an_instance_of Method }
      its(:receiver) { should eq String }
      its(:name) { should eq :new }
    end

    context "static method lookup" do
      context "implied ns" do
        before { ns.set_here(:String, String) }
        subject { compile.("String/new").res }
        it { should be_an_instance_of Method }
        its(:receiver) { should eq String }
        its(:name) { should eq :new }
      end

      context "fully-qualified" do
        subject { compile.("ruby/String/new").res }
        it { should be_an_instance_of Method }
        its(:receiver) { should eq String }
        its(:name) { should eq :new }
      end
    end
  end

  describe "sub-compilation behaviour" do
    it { expect { compile.("[a]")
                }.to raise_exception(Rouge::Namespace::VarNotFoundError) }

    context do
      before { ns.set_here(:a, :a) }
      it { expect { compile.("[a]")
                  }.to_not raise_exception }
    end

    it { expect { compile.("{b c}")
                }.to raise_exception(Rouge::Namespace::VarNotFoundError) }

    context do
      before { ns.set_here(:b, :b) }
      it { expect { compile.("{b c}")
                  }.to raise_exception(Rouge::Namespace::VarNotFoundError) }

      context do
        before { ns.set_here(:c, :c) }
        it { expect { compile.("{b c}")
                    }.to_not raise_exception }
      end
    end

    it { compile.("(let [a 'thing] (a | [b] b))").
           should eq read.("(let [a 'thing] (a | (fn [b] b)))") }

    it { compile.("()").should eq Rouge::Seq::Empty }
  end
end

# vim: set sw=2 et cc=80:
