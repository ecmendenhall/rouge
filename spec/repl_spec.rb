# encoding: utf-8
require 'spec_helper'
require 'rouge'

Rouge.boot!

describe Rouge::REPL do
  before do
    @ns = Rouge[:user].clear
    @ns.refer(Rouge[:"rouge.core"])
    @ns.refer(Rouge[:ruby])
  end

  describe "comp" do
    let(:comp) { Rouge::REPL::Completer }
    let(:fake_class_a) { Class.new }
    let(:fake_class_b) { Class.new }

    context "#new" do
      let(:completer) { Rouge::REPL::Completer.new(@ns) }

      it {
        completer.call("u").should include(:user)
        completer.call("Rouge").should include("Rouge.VERSION")
        completer.call("ruby/").should include("ruby/RUBY_VERSION")
        completer.call("ruby/Rouge.").should include("ruby/Rouge.VERSION")
      }
    end

    context "#search" do

      it "finds rouge namesapces and vars" do
        comp.search("r").should include(:"rouge.core")
        comp.search("r").should include(:ruby)
        comp.search("d").should include(:def)
        comp.search("rouge.core/").should include("rouge.core/seq")
      end

      it "finds Ruby modules and singleton meathods" do
        fake_class_a.define_singleton_method(:pop) {}
        fake_class_b.define_singleton_method(:toast) {}

        stub_const("Corn", fake_class_a)
        stub_const("Corn::Bread", fake_class_b)

        comp.search("C").should include(:Corn)
        comp.search("C").should_not include(:Bread)
        comp.search("Corn.").should include("Corn.Bread")
        comp.search("Corn/").should include("Corn/pop")
        comp.search("Corn.").should_not include("Corn/pop")
        comp.search("Corn/").should_not include("Corn.Bread")

        comp.search("ruby/C").should include("ruby/Corn")
        comp.search("ruby/Corn.").should include("ruby/Corn.Bread")
        comp.search("ruby/Corn/").should include("ruby/Corn/pop")
        comp.search("ruby/Corn.Bread/").should include("ruby/Corn.Bread/toast")
      end
    end

    context "#search_ruby" do
      let(:fake_class_a) { Class.new }
      let(:fake_class_b) { Class.new }

      it {
        fake_class_a.define_singleton_method(:pop) {}
        fake_class_b.define_singleton_method(:toast) {}

        stub_const("Corn", fake_class_a)
        stub_const("Corn::Bread", fake_class_b)

        comp.search_ruby("B").should include(:Corn)
        comp.search_ruby("Corn").should include("Corn.Bread")
        comp.search_ruby("Corn").should include("Corn/pop")
        comp.search_ruby("Corn.Bread").should include("Corn.Bread/toast")
      }
    end

    context "#rg_namespaces" do
      it {
        comp.rg_namespaces.should be_an_instance_of(Hash)
        comp.rg_namespaces.should include(:"rouge.core")
      }
    end

    context "#locate_module" do
      it {
        comp.locate_module("R").should eq(Object)
        comp.locate_module("Rouge").should eq(Rouge)
        comp.locate_module("Rouge.").should eq(Rouge)
        comp.locate_module("V", Rouge).should eq(Rouge)
        comp.locate_module("Rouge..").should eq(Rouge)
        comp.locate_module("Symbol", Rouge).should eq(Rouge::Symbol)
        comp.locate_module("Rouge.Symbol").should eq(Rouge::Symbol)
        comp.locate_module("Rouge.symbol").should eq(Rouge)
      }
    end

  end
end

# vim: set sw=2 et cc=80:
