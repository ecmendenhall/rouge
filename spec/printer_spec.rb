# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Printer do
  describe ".print" do
    context "numbers" do
      it { Rouge.print(12755, "").should eq "12755" }
      it { Rouge.print(Rational(1,2), "").should eq "1/2" }
    end

    context "symbols" do
      it { Rouge.print(Rouge::Symbol[:loki], "").should eq "loki" }
      it { Rouge.print(Rouge::Symbol[:/], "").should eq "/" }
      it { Rouge.print(Rouge::Symbol[:wah?], "").should eq "wah?" }
      it { Rouge.print(Rouge::Symbol[:"!ruby!"], "").should eq "!ruby!" }
      it { Rouge.print(Rouge::Symbol[:nil], "").should eq "nil" }
      it { Rouge.print(Rouge::Symbol[:true], "").should eq "true" }
      it { Rouge.print(Rouge::Symbol[:false], "").should eq "false" }
    end

    context "keywords" do
      context "plain keywords" do
        it { Rouge.print(:loki, "").should eq ":loki" }
        it { Rouge.print(:/, "").should eq ":/" }
        it { Rouge.print(:wah?, "").should eq ":wah?" }
        it { Rouge.print(:nil, "").should eq ":nil" }
        it { Rouge.print(:true, "").should eq ":true" }
        it { Rouge.print(:false, "").should eq ":false" }
      end

      context "string-symbols" do
        it { Rouge.print(:"!ruby!", "").should eq ":\"!ruby!\"" }
      end
    end

    context "strings" do
      context "plain strings" do
        it { Rouge.print("akashi yo", "").should eq "\"akashi yo\"" }
        it { Rouge.print("akashi\nwoah!", "").should eq "\"akashi\\nwoah!\"" }
      end

      context "escape sequences" do
        it { Rouge.print("here \" goes", "").should eq "\"here \\\" goes\"" }
        it { Rouge.print("here \\ goes", "").should eq "\"here \\\\ goes\"" }
        it { Rouge.print("\a\b\e\f\n", "").should eq "\"\\a\\b\\e\\f\\n\"" }
        it { Rouge.print("\r\t\v", "").should eq "\"\\r\\t\\v\"" }
      end
    end

    context "lists" do
      context "empty list" do
        it { Rouge.print(Rouge::Seq::Cons[], "").should eq "()" }
      end

      context "one-element lists" do
        it { Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:tiffany]], "").
                 should eq "(tiffany)" }
        it { Rouge.print(Rouge::Seq::Cons[:raaaaash], "").
                 should eq "(:raaaaash)" }
      end

      context "multiple-element lists" do
        it { Rouge.print(Rouge::Seq::Cons[1, 2, 3], "").should eq "(1 2 3)" }
        it { Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:true],
                                          Rouge::Seq::Cons[], [], "no"], "").
                 should eq "(true () [] \"no\")" }
      end

      context "nested lists" do
        it { Rouge.print(
                 Rouge::Seq::Cons[
                     Rouge::Seq::Cons[Rouge::Seq::Cons[3],
                                      Rouge::Seq::Cons[Rouge::Seq::Cons[]]],
                     9,
                     Rouge::Seq::Cons[Rouge::Seq::Cons[8],
                                      Rouge::Seq::Cons[8]]],
                 "").
                 should eq "(((3) (())) 9 ((8) (8)))" }
      end
    end

    context "vectors" do
      context "the empty vector" do
        it { Rouge.print([], "").should eq "[]" }
      end

      context "one-element vectors" do
        it { Rouge.print([Rouge::Symbol[:tiffany]], "").should eq "[tiffany]" }
        it { Rouge.print([:raaaaash], "").should eq "[:raaaaash]" }
      end

      context "multiple-element vectors" do
        it { Rouge.print([1, 2, 3], "").should eq "[1 2 3]" }
        it { Rouge.print([Rouge::Symbol[:true], Rouge::Seq::Cons[], [], "no"], "").
                 should eq "[true () [] \"no\"]" }
      end

      context "nested vectors" do
        it { Rouge.print([[[3], [[]]], 9, [[8], [8]]], "").
                 should eq "[[[3] [[]]] 9 [[8] [8]]]" }
      end
    end

    context "quotations" do
      it { Rouge.print(
               Rouge::Seq::Cons[Rouge::Symbol[:quote], Rouge::Symbol[:x]],
               "").
               should eq "'x" }
      it { Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:quote],
                       Rouge::Seq::Cons[Rouge::Symbol[:quote],
                       Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Symbol[:quote],
                       Rouge::Symbol[:x]]]]], "").
               should eq "''('x)" }
    end

    context "vars" do
      it { Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:var],
                                        Rouge::Symbol[:"x/y"]], "").
               should eq "#'x/y" }

      it { Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:var],
                       Rouge::Seq::Cons[Rouge::Symbol[:var],
                       Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Symbol[:var],
                       Rouge::Symbol[:"x/y"]]]]], "").
               should eq "#'#'(#'x/y)" }

      it { Rouge.print(Rouge::Var.new(:x, :y), "").should eq "#'x/y" }
    end

    context "maps" do
      context "the empty map" do
        it { Rouge.print({}, "").should eq "{}" }
      end

      context "one-element maps" do
        it { Rouge.print({Rouge::Symbol[:a] => 1}, "").should eq "{a 1}" }
        it { Rouge.print({"quux" => [Rouge::Symbol[:lambast]]}, "").
                 should eq "{\"quux\" [lambast]}" }
      end

      context "multiple-element maps" do
        # XXX(arlen): these tests rely on stable-ish Hash order
        it { Rouge.print({:a => 1, :b => 2}, "").should eq "{:a 1, :b 2}" }
        it { Rouge.print({:f => :f, :y => :y, :z => :z}, "").
                 should eq "{:f :f, :y :y, :z :z}" }
      end

      context "nested maps" do
        # XXX(arlen): this test relies on stable-ish Hash order
        it { Rouge.print({:a => {:z => 9},
                          :b => {:q => Rouge::Symbol[:q]}}, "").
                 should eq "{:a {:z 9}, :b {:q q}}" }
        it { Rouge.print({{9 => 7} => 5}, "").should eq "{{9 7} 5}" }
      end
    end

    context "fundamental objects" do
      it { Rouge.print(nil, "").should eq "nil" }
      it { Rouge.print(true, "").should eq "true" }
      it { Rouge.print(false, "").should eq "false" }
    end

    context "Ruby classes" do
      it { Rouge.print(Object, "").should eq "ruby/Object" }
      it { Rouge.print(Class, "").should eq "ruby/Class" }
      it { Rouge.print(Rouge::Context, "").should eq "ruby/Rouge.Context" }

      let(:anon) { Class.new }
      it { Rouge.print(anon, "").should eq anon.inspect }
    end

    context "builtin forms" do
      it { Rouge.print(Rouge::Builtin[Rouge::Builtins.method(:let)], "").
               should eq "rouge.builtin/let" }
      it { Rouge.print(Rouge::Builtin[Rouge::Builtins.method(:def)], "").
               should eq "rouge.builtin/def" }
    end

    context "unknown forms" do
      let(:l) { lambda {} }
      it { Rouge.print(l, "").should eq l.inspect }
    end

    context "regexp" do
      let(:rx) { Regexp.new("abc") }
      it { Rouge.print(rx, "").should eq "#\"abc\"" }
    end
  end
end

# vim: set sw=2 et cc=80:
