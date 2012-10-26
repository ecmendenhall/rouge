# rouge [![Build Status](https://secure.travis-ci.org/unnali/rouge.png)](http://travis-ci.org/unnali/rouge)

Ruby + Clojure = Rouge.

## why?

* Ruby's gems are fun to use.
* Quick boot time (currently around 0.1s).
* Clojure is awesome.

## quickstart

Rouge is not yet mature enough to have an installer or distributions.  Just
clone the source and run the `rouge` script to start:

    git clone git://github.com/unnali/rouge
    cd rouge
    bundle install
    bin/rouge

You'll see the `user=>` prompt.  Enjoy!  (Expect plenty of stack traces.)

## example

See [boot.rg](https://github.com/unnali/rouge/blob/master/lib/boot.rg),
[em-rg](https://github.com/unnali/em-rg),
[mechanize-rg](https://github.com/unnali/mechanize-rg), but to demonstrate
salient features:

    ; define a macro
    (defmacro defn [name args & body]
      `(def ~name (fn ~name ~args ~@body)))

    ; call a Ruby method on Kernel (if the ruby namespace is referred)
    (defn require [lib]
      (.require Kernel lib))

    ; call a Ruby method on an Array with a block argument
    (defn reduce [f coll]
      (.inject coll | f))

    ; using Ruby's AMQP gem with an inline block
    (.subscribe queue {:ack true} | [metadata payload]
      (puts (str "got a message: " payload))
      (.ack metadata))

    ; copied from core.clj and modified to work with our currently smaller core
    (defmacro binding [bindings & body]
      (let [var-ize (fn [var-vals]
                      (.flatten
                        (map
                          (fn [pair]
                            (let [key (first pair)
                                  val (second pair)]
                              [`(.name (var ~key)) val]))
                          (.each_slice var-vals 2))
                        1))]
      `(try
         (push-thread-bindings (hash-map ~@(var-ize bindings)))
         ~@body
         (finally
           (pop-thread-bindings)))))

What about in Rails?

    $ r c -- -I../rouge/lib -rrouge
    Loading development environment (Rails 3.2.6)
    1.9.3p194 :002 > Rouge::REPL.repl []
    user=> (.where ruby/Content {:id 1})
      Content Load (0.7ms)  SELECT "contents".* FROM "contents" WHERE "contents"."id" = 1
    [#<Content id: 1, content_group_id: 1, name: "welcome", content: "blah blah", created_at: "2012-08-26 11:30:50", updated_at: "2012-08-26 11:50:27", order: nil>]
    user=>

## discuss

* [rouge-talk mailing list](https://groups.google.com/forum/#!forum/rouge-talk) (email <rouge-talk@googlegroups.com>) for announcements and chat
* I hang out on `#rouge` on Freenode.

## TODO

See [TODO](https://github.com/unnali/rouge/blob/master/TODO), but big ones
include:

* seqs ([in progress](https://github.com/unnali/rouge/pull/3))
* persistent datastructures everywhere
* defprotocol

## contributions

**Yes, please!**  The usual dance would be:

* Make a topic branch.
* Do your tests, do your thing.
* Pull request!

## authorship

Original author: [Arlen Christian Mart Cuss](https://github.com/unnali).

Unreserved thanks to the following people for their contributions.

* [Russell Whitaker](https://github.com/russellwhitaker)
* [Misha Moroshko](https://github.com/moroshko)

## copyright and licensing

The [MIT license](http://opensource.org/licenses/MIT).

Copyright &copy; 2012 Arlen Christian Mart Cuss

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
