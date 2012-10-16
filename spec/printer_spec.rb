# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Printer do
  describe "the print method" do
    it "should print numbers" do
      Rouge.print(12755, "").should eq "12755"
    end

    it "should print symbols" do
      Rouge.print(Rouge::Symbol[:loki], "").should eq "loki"
      Rouge.print(Rouge::Symbol[:/], "").should eq "/"
      Rouge.print(Rouge::Symbol[:wah?], "").should eq "wah?"
      Rouge.print(Rouge::Symbol[:"!ruby!"], "").should eq "!ruby!"
      Rouge.print(Rouge::Symbol[:nil], "").should eq "nil"
      Rouge.print(Rouge::Symbol[:true], "").should eq "true"
      Rouge.print(Rouge::Symbol[:false], "").should eq "false"
    end

    describe "keywords" do
      it "should print plain keywords" do
        Rouge.print(:loki, "").should eq ":loki"
        Rouge.print(:/, "").should eq ":/"
        Rouge.print(:wah?, "").should eq ":wah?"
        Rouge.print(:nil, "").should eq ":nil"
        Rouge.print(:true, "").should eq ":true"
        Rouge.print(:false, "").should eq ":false"
      end

      it "should print string-symbols" do
        Rouge.print(:"!ruby!", "").should eq ":\"!ruby!\""
      end
    end

    describe "strings" do
      it "should print plain strings" do
        Rouge.print("akashi yo", "").should eq "\"akashi yo\""
        Rouge.print("akashi \n woah!", "").should eq "\"akashi \\n woah!\""
      end

      it "should print escape sequences" do
        Rouge.print("here \" goes", "").should eq "\"here \\\" goes\""
        Rouge.print("here \\ goes", "").should eq "\"here \\\\ goes\""
        Rouge.print("\a\b\e\f\n", "").should eq "\"\\a\\b\\e\\f\\n\""
        Rouge.print("\r\t\v", "").should eq "\"\\r\\t\\v\""
      end
    end

    describe "lists" do
      it "should print the empty list" do
        Rouge.print(Rouge::Seq::Cons[], "").should eq "()"
      end

      it "should print one-element lists" do
        Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:tiffany]], "").
            should eq "(tiffany)"
        Rouge.print(Rouge::Seq::Cons[:raaaaash], "").
            should eq "(:raaaaash)"
      end

      it "should print multiple-element lists" do
        Rouge.print(Rouge::Seq::Cons[1, 2, 3], "").should eq "(1 2 3)"
        Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:true],
                                Rouge::Seq::Cons[], [], "no"], "").
            should eq "(true () [] \"no\")"
      end

      it "should print nested lists" do
        Rouge.print(Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Seq::Cons[3],
                    Rouge::Seq::Cons[Rouge::Seq::Cons[]]], 9,
                    Rouge::Seq::Cons[Rouge::Seq::Cons[8], Rouge::Seq::Cons[8]]], "").
            should eq "(((3) (())) 9 ((8) (8)))"
      end
    end

    describe "vectors" do
      it "should print the empty vector" do
        Rouge.print([], "").should eq "[]"
      end

      it "should print one-element vectors" do
        Rouge.print([Rouge::Symbol[:tiffany]], "").should eq "[tiffany]"
        Rouge.print([:raaaaash], "").should eq "[:raaaaash]"
      end

      it "should print multiple-element vectors" do
        Rouge.print([1, 2, 3], "").should eq "[1 2 3]"
        Rouge.print([Rouge::Symbol[:true], Rouge::Seq::Cons[], [], "no"], "").
            should eq "[true () [] \"no\"]"
      end

      it "should print nested vectors" do
        Rouge.print([[[3], [[]]], 9, [[8], [8]]], "").
            should eq "[[[3] [[]]] 9 [[8] [8]]]"
      end
    end

    describe "quotations" do
      it "should print (QUOTE X) as 'X" do
        Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:quote], Rouge::Symbol[:x]], "").
            should eq "'x"
      end

      it "should print (QUOTE (QUOTE ((QUOTE X)))) as ''('X)" do
        Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:quote],
                    Rouge::Seq::Cons[Rouge::Symbol[:quote],
                    Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Symbol[:quote],
                    Rouge::Symbol[:x]]]]], "").
            should eq "''('x)"
      end
    end

    describe "vars" do
      it "should print (VAR X/Y) as #'X/Y" do
        Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:var],
                                Rouge::Symbol[:"x/y"]], "").
            should eq "#'x/y"
      end

      it "should print (VAR (VAR ((VAR X/Y)))) as #'#'(#'X/Y)" do
        Rouge.print(Rouge::Seq::Cons[Rouge::Symbol[:var],
                    Rouge::Seq::Cons[Rouge::Symbol[:var],
                    Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Symbol[:var],
                    Rouge::Symbol[:"x/y"]]]]], "").
            should eq "#'#'(#'x/y)"
      end

      it "should print the var #'X/Y itself as #'X/Y" do
        Rouge.print(Rouge::Var.new(:x, :y), "").should eq "#'x/y"
      end
    end

    describe "maps" do
      it "should print the empty map" do
        Rouge.print({}, "").should eq "{}"
      end

      it "should print one-element maps" do
        Rouge.print({Rouge::Symbol[:a] => 1}, "").should eq "{a 1}"
        Rouge.print({"quux" => [Rouge::Symbol[:lambast]]}, "").
            should eq "{\"quux\" [lambast]}"
      end

      it "should print multiple-element maps" do
        # XXX(arlen): these tests rely on stable-ish Hash order
        Rouge.print({:a => 1, :b => 2}, "").should eq "{:a 1, :b 2}"
        Rouge.print({:f => :f, :y => :y, :z => :z}, "").
            should eq "{:f :f, :y :y, :z :z}"
      end

      it "should print nested maps" do
        # XXX(arlen): this test relies on stable-ish Hash order
        Rouge.print({:a => {:z => 9},
                    :b => {:q => Rouge::Symbol[:q]}}, "").
            should eq "{:a {:z 9}, :b {:q q}}"
        Rouge.print({{9 => 7} => 5}, "").should eq "{{9 7} 5}"
      end
    end

    it "should print the fundamental objects" do
      Rouge.print(nil, "").should eq "nil"
      Rouge.print(true, "").should eq "true"
      Rouge.print(false, "").should eq "false"
    end

    it "should print Ruby classes in their namespace" do
      Rouge.print(Object, "").should eq "ruby/Object"
      Rouge.print(Class, "").should eq "ruby/Class"
      Rouge.print(Rouge::Context, "").should eq "ruby/Rouge.Context"
      anon = Class.new
      Rouge.print(anon, "").should eq anon.inspect
    end

    it "should print builtin forms in their namespace" do
      Rouge.print(Rouge::Builtin[Rouge::Builtins.method(:let)], "").
          should eq "rouge.builtin/let"
      Rouge.print(Rouge::Builtin[Rouge::Builtins.method(:def)], "").
          should eq "rouge.builtin/def"
    end

    describe "unknown form behaviour" do
      it "should print the Ruby inspection of unknown forms" do
        l = lambda {}
        Rouge.print(l, "").should eq l.inspect
      end
    end
  end
end

# vim: set sw=2 et cc=80:
