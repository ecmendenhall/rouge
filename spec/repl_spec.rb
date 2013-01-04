# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::REPL do
  before do
    @ns = Rouge[:user].clear
    @ns.refer(Rouge[:"rouge.core"])
    @ns.refer(Rouge[:ruby])
  end

  describe "tab completion" do
    let(:complete) { Rouge::REPL.completion_proc(@ns) }

    it { complete.should be_an_instance_of(Proc) }

    context "rouge builtins" do
      it { complete.call('d').should include(:def) }
      it { complete.call('l').should include(:let) }
    end

    describe "namespaces" do
      it { complete.call('rouge').should include(:"rouge.core") }

      it {
        complete.call('rouge.core')
        Readline.completion_append_character.should eq("/")
      }

      context "with solidus" do
        it {
          complete.call('user/').should be_empty
          Readline.completion_append_character.should be_nil
        }

        it {
          @ns.set_here :xylaphone, nil
          @ns.set_here :"x-ray", nil
          @ns.set_here :yellow, nil
          complete.call('user/').should include("user/yellow")
          complete.call('user/x').should include("user/x-ray")
        }
      end
    end

    describe "ruby" do
      it { complete.call('R').should include(:RUBY_VERSION) }

      context "with solidus" do
        it { complete.call('ruby/').should include("ruby/RUBY_VERSION") }
        it { complete.call('ruby/R').should include("ruby/RUBY_VERSION") }
      end
    end
  end
end

# vim: set sw=2 et cc=80:
