# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::REPL do
  describe "comp" do
    let(:ns) { Rouge[:user].clear }
    let(:comp) { Rouge::REPL::Completer }
    let(:fake_class_a) { Class.new }
    let(:fake_class_b) { Class.new }

    before {
      stub_const("Corn", fake_class_a)
      stub_const("Corn::Bread", fake_class_b)
      fake_class_a.define_singleton_method(:pop) {}
      fake_class_b.define_singleton_method(:toast) {}
      ns.set_here(:pop, "corn")
    }

    context "#new" do
      let(:comp) { Rouge::REPL::Completer.new(ns) }
      it { comp.call("u").should include(:user) }
      it { comp.call("p").should include(:pop) }
      it { comp.call("Rouge").should include("Rouge.VERSION") }
      it { comp.call("ruby/").should include("ruby/RUBY_VERSION") }
      it { comp.call("ruby/Rouge.").should include("ruby/Rouge.VERSION") }
    end

    context "#search" do
      it { comp.search("u").should include(:user) }
      it { comp.search("r").should include(:ruby) }
      it { comp.search("d").should include(:def) }
      it { comp.search("user/").should include("user/pop") }
      it { comp.search("C").should include(:Corn) }
      it { comp.search("C").should_not include(:Bread) }
      it { comp.search("Corn.").should include("Corn.Bread") }
      it { comp.search("Corn/").should include("Corn/pop") }
      it { comp.search("Corn.").should_not include("Corn/pop") }
      it { comp.search("Corn/").should_not include("Corn.Bread") }
      it { comp.search("ruby/C").should include("ruby/Corn") }
      it { comp.search("ruby/Corn.").should include("ruby/Corn.Bread") }
      it { comp.search("ruby/Corn/").should include("ruby/Corn/pop") }
      it { comp.search("ruby/Corn.Bread/").should include("ruby/Corn.Bread/toast") }
    end

    context "#search_ruby" do
      it { comp.search_ruby("B").should include(:Corn) }
      it { comp.search_ruby("Corn").should include("Corn.Bread") }
      it { comp.search_ruby("Corn").should include("Corn/pop") }
      it { comp.search_ruby("Corn.Bread").should include("Corn.Bread/toast") }
    end

    context "#rg_namespaces" do
      it { comp.send(:rg_namespaces).should be_an_instance_of(Hash) }
      it { comp.send(:rg_namespaces).should include(:user) }
    end

    context "#locate_module" do
      it { comp.locate_module("R").should eq(Object) }
      it { comp.locate_module("Rouge").should eq(Rouge) }
      it { comp.locate_module("Rouge.").should eq(Rouge) }
      it { comp.locate_module("V", Rouge).should eq(Rouge) }
      it { comp.locate_module("Rouge..").should eq(Rouge) }
      it { comp.locate_module("Symbol", Rouge).should eq(Rouge::Symbol) }
      it { comp.locate_module("Rouge.Symbol").should eq(Rouge::Symbol) }
      it { comp.locate_module("Rouge.symbol").should eq(Rouge) }
    end
  end
end

# vim: set sw=2 et cc=80:
