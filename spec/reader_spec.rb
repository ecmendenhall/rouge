# encoding: utf-8
require 'spec_helper'
require 'rouge'

describe Rouge::Reader do
  before do
    @ns = Rouge[:"user.spec"].clear
    @ns.refer Rouge[:"rouge.builtin"]
  end

  describe "reading numbers" do
    it { @ns.read("12755").should eq 12755 }
    it { @ns.read("2_50_9").should eq 2509 }
    it { @ns.read("-999").should eq(-999) }
    it { @ns.read("+1704").should eq(1704) }

    context "floats" do
      it { @ns.read("23.0").should be_an_instance_of Float }
      it { @ns.read("23.0").should eq 23.0 }
      it { @ns.read("23.1").should eq 23.1 }
      it { @ns.read("-23.1").should eq(-23.1) }
      it { @ns.read("+17.04").should eq(17.04) }
      it { @ns.read("+1_000e-3").should eq(1.0) }
      it { @ns.read("+1E+3").should eq(1000) }
    end

    context "binary" do
      it { @ns.read("+0b10").should eq(2) }
      it { @ns.read("-0b10").should eq(-2) }
    end

    context "hexadecimal" do
      it { @ns.read("+0xf").should eq(15) }
      it { @ns.read("-0xf").should eq(-15) }
    end

    context "octal" do
      it { @ns.read("+0333").should eq(219) }
      it { @ns.read("-0333").should eq(-219) }
    end

    context "bad numbers" do
      it {
        expect {
          @ns.read("1.2.3")
        }.to raise_exception Rouge::Reader::NumberFormatError
      }

      it {
        expect {
          @ns.read("12..")
        }.to raise_exception Rouge::Reader::NumberFormatError
      }
    end
  end

  describe "symbols" do
    it { @ns.read("loki").should eq Rouge::Symbol[:loki] }
    it { @ns.read("wah?").should eq Rouge::Symbol[:wah?] }
    it { @ns.read("!ruby!").should eq Rouge::Symbol[:"!ruby!"] }
    it { @ns.read("nil").should eq Rouge::Symbol[:nil] }
    it { @ns.read("nil").should eq nil }
    it { @ns.read("true").should eq Rouge::Symbol[:true] }
    it { @ns.read("true").should eq true }
    it { @ns.read("false").should eq Rouge::Symbol[:false] }
    it { @ns.read("false").should eq false }
    it { @ns.read("&").should eq Rouge::Symbol[:&] }
    it { @ns.read("*").should eq Rouge::Symbol[:*] }
    it { @ns.read("-").should eq Rouge::Symbol[:-] }
    it { @ns.read("+").should eq Rouge::Symbol[:+] }
    it { @ns.read("/").should eq Rouge::Symbol[:/] }
    it { @ns.read("|").should eq Rouge::Symbol[:|] }
    it { @ns.read("$").should eq Rouge::Symbol[:"$"] }
    it { @ns.read(".").should eq Rouge::Symbol[:"."] }
    it { @ns.read(".[]").should eq Rouge::Symbol[:".[]"] }
    it { @ns.read("=").should eq Rouge::Symbol[:"="] }
    it { @ns.read("%").should eq Rouge::Symbol[:"%"] }
    it { @ns.read(">").should eq Rouge::Symbol[:">"] }
    it { @ns.read("<").should eq Rouge::Symbol[:"<"] }
    it { @ns.read("%50").should eq Rouge::Symbol[:"%50"] }
    it { @ns.read("xyz#").should eq Rouge::Symbol[:"xyz#"] }
    it { @ns.read("-@").should eq Rouge::Symbol[:-@] }
    it { @ns.read(".-@").should eq Rouge::Symbol[:".-@"] }
    it { @ns.read("+@").should eq Rouge::Symbol[:+@] }
    it { @ns.read(".+@").should eq Rouge::Symbol[:".+@"] }
  end

  describe "keywords" do
    context "plain keywords" do
      it { @ns.read(":loki").should eq :loki }
      it { @ns.read(":/").should eq :/ }
      it { @ns.read(":wah?").should eq :wah? }
      it { @ns.read(":nil").should eq :nil }
      it { @ns.read(":true").should eq :true }
      it { @ns.read(":false").should eq :false }
    end

    context "string-symbols" do
      it { @ns.read(":\"!ruby!\"").should eq :"!ruby!" }
    end
  end

  describe "strings" do
    context "plain strings" do
      it { @ns.read("\"akashi yo\"").should eq "akashi yo" }
      it { @ns.read("\"akashi \n woah!\"").should eq "akashi \n woah!" }
    end

    context "escape sequences" do
      it { @ns.read("\"here \\\" goes\"").should eq "here \" goes" }
      it { @ns.read("\"here \\\\ goes\"").should eq "here \\ goes" }
      it { @ns.read("\"\\a\\b\\e\\f\\n\\r\"").should eq "\a\b\e\f\n\r" }
      it { @ns.read("\"\\s\\t\\v\"").should eq "\s\t\v" }
    end

    context "read as frozen" do
      it { @ns.read("\"bah\"").should be_frozen }
    end
  end

  describe "lists" do
    context "empty list" do
      it { @ns.read("()").should eq Rouge::Seq::Cons[] }
    end

    context "one-element lists" do
      it { @ns.read("(tiffany)").
             should eq Rouge::Seq::Cons[Rouge::Symbol[:tiffany]] }
      it { @ns.read("(:raaaaash)").
             should eq Rouge::Seq::Cons[:raaaaash] }
    end

    context "multiple-element lists" do
      it { @ns.read("(1 2 3)").should eq Rouge::Seq::Cons[1, 2, 3] }
      it { @ns.read("(true () [] \"no\")").
             should eq Rouge::Seq::Cons[Rouge::Symbol[:true],
                                        Rouge::Seq::Cons[],
                                        [],
                                        "no"] }
    end

    context "nested lists" do
      it { @ns.read("(((3) (())) 9 ((8) (8)))").
             should eq Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Seq::Cons[3],
             Rouge::Seq::Cons[Rouge::Seq::Cons[]]], 9,
             Rouge::Seq::Cons[Rouge::Seq::Cons[8], Rouge::Seq::Cons[8]]] }
    end

    context "read as frozen" do
      it { @ns.read("()").should be_frozen }
      it { @ns.read("(1)").should be_frozen }
      it { @ns.read("(1 2)").should be_frozen }
    end
  end

  describe "vectors" do
    context "the empty vector" do
      it { @ns.read("[]").should eq [] }
    end

    context "one-element vectors" do
      it { @ns.read("[tiffany]").should eq [Rouge::Symbol[:tiffany]] }
      it { @ns.read("[:raaaaash]").should eq [:raaaaash] }
    end

    context "multiple-element vectors" do
      it { @ns.read("[1 2 3]").should eq [1, 2, 3] }
      it { @ns.read("[true () [] \"no\"]").
             should eq [Rouge::Symbol[:true], Rouge::Seq::Cons[], [], "no"] }
    end

    context "nested vectors" do
      it { @ns.read("[[[3] [[]]] 9 [[8] [8]]]").
             should eq [[[3], [[]]], 9, [[8], [8]]] }
    end

    context "read as frozen" do
      it { @ns.read("[]").should be_frozen }
      it { @ns.read("[1]").should be_frozen }
      it { @ns.read("[1 2]").should be_frozen }
    end
  end

  describe "sets" do
    context "the empty set" do
      it { @ns.read('#{}').should eq Set.new }
    end

    context "multiple-element sets" do
      it { @ns.read('#{1 2 3}').should eq Set.new.add(1).add(2).add(3) }
      it { @ns.read('#{true () [] "no"}').
           should eq Set.new([Rouge::Symbol[:true],
                              Rouge::Seq::Cons[],
                              [],
                              "no"]) }
    end

    context "nested sets" do
      it { @ns.read('#{#{1} #{2} #{3}}').
            should eq Set.new([Set.new([1]), Set.new([2]), Set.new([3])]) }
    end

    context "read as frozen" do
      it { @ns.read('#{}').should be_frozen }
      it { @ns.read('#{1}').should be_frozen }
      it { @ns.read('#{1 2}').should be_frozen }
    end
  end

  describe "quotations" do
    it { @ns.read("'x").
           should eq Rouge::Seq::Cons[Rouge::Symbol[:quote],
                                      Rouge::Symbol[:x]] }

    it { @ns.read("''('x)").
           should eq Rouge::Seq::Cons[Rouge::Symbol[:quote],
                     Rouge::Seq::Cons[Rouge::Symbol[:quote],
                     Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Symbol[:quote],
                                             Rouge::Symbol[:x]]]]] }
  end

  describe "vars" do
    it { @ns.read("#'x").
           should eq Rouge::Seq::Cons[Rouge::Symbol[:var], Rouge::Symbol[:x]] }

    it { @ns.read("#'#'(#'x)").
           should eq Rouge::Seq::Cons[Rouge::Symbol[:var],
                     Rouge::Seq::Cons[Rouge::Symbol[:var],
                     Rouge::Seq::Cons[Rouge::Seq::Cons[Rouge::Symbol[:var],
                                             Rouge::Symbol[:x]]]]] }
  end

  describe "maps" do
    context "the empty map" do
      it { @ns.read("{}").should eq({}) }
    end

    context "one-element maps" do
      it { @ns.read("{a 1}").to_s.should eq({Rouge::Symbol[:a] => 1}.to_s) }
      it { @ns.read("{\"quux\" [lambast]}").
             should eq({"quux" => [Rouge::Symbol[:lambast]]}) }
    end

    context "multiple-element maps" do
      it { @ns.read("{:a 1 :b 2}").should eq({:a => 1, :b => 2}) }
      it { @ns.read("{:f :f, :y :y\n:z :z}").
             should eq({:f => :f, :y => :y, :z => :z}) }
    end

    context "nested maps" do
      it { @ns.read("{:a {:z 9} :b {:q q}}").should eq(
             {:a => {:z => 9}, :b => {:q => Rouge::Symbol[:q]}}) }
      it { @ns.read("{{9 7} 5}").should eq({{9 => 7} => 5}) }
    end

    context "read as frozen" do
      it { @ns.read("{}").should be_frozen }
      it { @ns.read("{:a 1}").should be_frozen }
    end
  end

  describe "whitespace behaviour" do
    it { expect { @ns.read(":hello    \n\n\t\t  ").should eq :hello
                }.to_not raise_exception }

    it { expect { @ns.read("[1 ]").should eq [1]
                }.to_not raise_exception }

    it { expect { @ns.read("  [   2 ] ").should eq [2]
                }.to_not raise_exception }
  end

  describe "empty reads" do
    it { expect { @ns.read("")
                }.to raise_exception(Rouge::Reader::EOFError) }

    it { expect { @ns.read("    \n         ")
                }.to raise_exception(Rouge::Reader::EOFError) }
  end

  describe "comments" do
    it { @ns.read("42 ;what!").should eq 42 }
    it { @ns.read("[42 ;what!\n15]").should eq [42, 15] }

    it { expect { @ns.read(";what!")
                }.to raise_exception(Rouge::Reader::EOFError) }

    it { @ns.read(";what!\nhmm").should eq Rouge::Symbol[:hmm] }
  end

  describe "syntax-quoting" do
    describe "non-cons lists" do
      context "quoting non-cons lists" do
        it { @ns.read('`3').should eq @ns.read("'3") }
        it { @ns.read('`"my my my"').should eq @ns.read(%{'"my my my"}) }
      end

      context "dequoting within non-cons lists" do
        it { @ns.read('`~3').should eq @ns.read("3") }
        it { @ns.read('``~3').should eq @ns.read("'3") }
        it { @ns.read('``~~3').should eq @ns.read("3") }
      end

      context "qualifying symbols" do
        it { @ns.read('`a').should eq @ns.read("'user.spec/a") }
      end

      context "not qualifying special symbols" do
        it { @ns.read('`.a').should eq @ns.read("'.a") }
        it { @ns.read('`&').should eq @ns.read("'&") }
        it { @ns.read('`|').should eq @ns.read("'|") }
      end
    end

    describe "cons-lists" do
      context "quoting cons lists" do
        it { @ns.read('`(1 2)').should eq @ns.read("(list '1 '2)") }
        it { @ns.read('`(a b)').
               should eq @ns.read("(list 'user.spec/a 'user.spec/b)") }
      end

      context "dequoting within cons lists" do
        it { @ns.read('`(a ~b)').should eq @ns.read("(list 'user.spec/a b)") }

        it { @ns.read('`(a ~(b `(c ~d)))').
            should eq @ns.read("(list 'user.spec/a (b " \
                               "(list 'user.spec/c d)))") }

        # Should the below include 'rouge.builtin/quote as it does?
        # Or should that be 'quote?  Clojure reads it so.
        it { @ns.read('`(a `(b ~c))').
            should eq @ns.read("(list 'user.spec/a (list 'user.spec/list " \
                               "(list 'rouge.builtin/quote 'user.spec/b) " \
                               "'user.spec/c))") }

        it { @ns.read('`~`(x)').should eq @ns.read("(list 'user.spec/x)") }
      end

      context "dequoting within maps" do
        it { @ns.read('`{a ~b}').to_s.
               should eq @ns.read("{'user.spec/a b}").to_s }
      end

      context "splicing within seqs and vectors" do
        it { @ns.read('`(a ~@b c)').
               should eq @ns.read("(seq (concat (list 'user.spec/a) b " \
                                  "(list 'user.spec/c)))") }

        it { @ns.read('`(~@(a b) ~c)').
               should eq @ns.read("(seq (concat (a b) (list c)))") }

        it do
          @ns.read('`[a ~@b c]').should eq @ns.read(<<-ROUGE)
            (apply vector (concat (list 'user.spec/a) b (list 'user.spec/c)))
          ROUGE
        end

        it { @ns.read('`[~@(a b) ~c]').
               should eq @ns.read("(apply vector (concat (a b) (list c)))") }
      end
    end

    describe "gensyms" do
      context "reading as unique in each invocation" do
        let(:a1) { @ns.read('`a#') }
        let(:a2) { @ns.read('`a#') }
        it { a1.to_s.should_not eq a2.to_s }
      end

      context "reading identically within each invocation" do
        let(:r) do
          @ns.read('`(a# a# `(a# a#))').
            map {|e| e.respond_to?(:to_a) ? e.to_a : e}.to_a.flatten.
            flat_map {|e| e.respond_to?(:to_a) ? e.to_a : e}.
            flat_map {|e| e.respond_to?(:to_a) ? e.to_a : e}.
            find_all {|e|
              e.is_a?(Rouge::Symbol) and e.name.to_s =~ /^a/
            }
        end

        it { r.should have(4).items }
        it { r[0].should eq r[1] }
        it { r[2].should eq r[3] }
        it { r[0].should_not eq r[2] }
      end
    end
  end

  describe "anonymous functions" do
    it { @ns.read('#(1)').should eq @ns.read('(fn [] (1))') }
    it { @ns.read('#(do 1)').should eq @ns.read('(fn [] (do 1))') }
    it { @ns.read('#(%)').should eq @ns.read('(fn [%1] (%1))') }
    it { @ns.read('#(%2)').should eq @ns.read('(fn [%1 %2] (%2))') }
    it { @ns.read('#(%5)').should eq @ns.read('(fn [%1 %2 %3 %4 %5] (%5))') }
    it { @ns.read('#(%2 %)').should eq @ns.read('(fn [%1 %2] (%2 %1))') }
  end

  describe "metadata" do
    context "reading" do
      subject { @ns.read('^{:x 1} y') }
      it { should eq Rouge::Symbol[:y] }
      its(:meta) { should eq({:x => 1}) }
    end

    context "stacking" do
      subject { @ns.read('^{:y 2} ^{:y 3 :z 2} y') }
      it { should eq Rouge::Symbol[:y] }
      its(:meta) { should include({:y => 2, :z => 2}) }
    end

    context "assigning tags" do
      subject { @ns.read('^"xyz" y') }
      it { should eq Rouge::Symbol[:y] }
      its(:meta) { should include({:tag => "xyz"}) }
    end

    context "assigning symbol markers" do
      subject { @ns.read('^:blargh y') }
      it { should eq Rouge::Symbol[:y] }
      its(:meta) { should include({:blargh => true}) }
    end
  end

  describe "deref" do
    it { @ns.read('@(boo)').should eq @ns.read('(rouge.core/deref (boo))') }
  end

  describe "multiple reading" do
    let(:r) { Rouge::Reader.new(@ns, "a b c") }

    it do
      r.lex.should eq Rouge::Symbol[:a]
      r.lex.should eq Rouge::Symbol[:b]
      r.lex.should eq Rouge::Symbol[:c]

      expect { r.lex }.to raise_exception(Rouge::Reader::EOFError)
    end
  end

  describe "the ns property" do
    it { Rouge::Reader.new(@ns, "").ns.should be @ns }
  end

  describe "the comment dispatch" do
    it { @ns.read('#_(xyz abc) :f').should eq :f }
  end

  describe "regexp" do
    it { @ns.read('#"abc"').should be_an_instance_of Regexp }
  end

  describe "bad reads" do
    let(:ex) { Rouge::Reader::EndOfDataError }
    it { expect { @ns.read('(') }.to raise_exception(ex) }
    it { expect { @ns.read('{') }.to raise_exception(ex) }
    it { expect { @ns.read('[') }.to raise_exception(ex) }
    it { expect { @ns.read('"') }.to raise_exception(ex) }
    it { expect { @ns.read("'") }.to raise_exception(ex) }
    it { expect { @ns.read('`') }.to raise_exception(ex) }
    it { expect { @ns.read('~') }.to raise_exception(ex) }
    it { expect { @ns.read('@') }.to raise_exception(ex) }
    it { expect { @ns.read('#(') }.to raise_exception(ex) }
    it { expect { @ns.read('#{') }.to raise_exception(ex) }
    it { expect { @ns.read("#'") }.to raise_exception(ex) }
    it { expect { @ns.read("#_") }.to raise_exception(ex) }
    it { expect { @ns.read('#"') }.to raise_exception(ex) }
  end
end

# vim: set sw=2 et cc=80:
