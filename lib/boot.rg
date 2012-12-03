;; -*- mode: clojure; -*-

(ns ^{:doc "The Rouge core."
      :author "Arlen Christian Mart Cuss"}
  rouge.core
  (:use ruby))

(def seq (fn rouge.core/seq [coll]
           (.seq Rouge.Seq coll)))

(def concat (fn rouge.core/concat [& lists]
              ; XXX lazy seq
              (seq (.inject (.to_a (.map lists | .to_a)) | .+))))

(def list (fn rouge.core/list [& elements]
            elements))

(defmacro defn [name args & body]
  (let [fn-name (.intern (.join [(.name (.ns (context))) (.name name)] "/"))]
    `(def ~name (fn ~(Rouge.Symbol. fn-name) ~args ~@body))))

(defmacro when [cond & body]
  `(if ~cond
     (do
       ~@body)))

(defn vector [& args]
  (.to_a args))

(defmacro lazy-seq [& body]
  `(Rouge.Seq.Lazy. (fn [] ~@body)))

(defn reduce [f coll]
  (.inject (.to_a coll) | f))

(defmacro when [cond & body]
  `(if ~cond
     (do
       ~@body)))

(defn cons [head tail]
  (Rouge.Seq.Cons. head tail))

(defn count [coll]
  (.count coll))

(defn = [a b]
  (.== a b))

(defn nil? [x]
  (.nil? x))

(defn identical? [x y]
  "Returns true if x and y are the same object."
  (= (.object_id x) (.object_id y)))

(defmacro or
  ([])
  ([x] x)
  ([x & xs] `(let [r# ~x]
               (if r# r# (or ~@xs)))))

(defmacro and
  ([] true)
  ([x] x)
  ([x & xs] `(let [r# ~x]
               (if (not r#) r# (and ~@xs)))))

(defn empty? [coll]
  (or (nil? coll)
      (= 0 (count coll))))

(defn map [f coll]
  (lazy-seq
    (if (empty? coll)
      nil
      (let [[hd & tl] coll]
        (cons (f hd) (map f tl))))))

(defn str [& args]
  (let [args (.to_a (map .to_s args))]
    (.join args "")))

(defn pr-str [& args]
  (let [args (.to_a (map #(.print Rouge % (String.)) args))]
    (.join args " ")))

(defn print [& args]
  (.print Kernel (apply pr-str args)))

(defn puts [& args]
  (.print Kernel (apply str args) "\n"))

(defn class [object]
  (.class object))

(defn sequential? [coll]
  (or (.is_a? coll Rouge.Seq.ISeq)
      (.is_a? coll Array)))

(defn not [bool]
  (or (= bool nil)
      (= bool false)))

(defn + [& args]
  (if (empty? args)
    0
    (reduce .+ args)))

(defn - [a & args]
  (if (= () args)
    (.-@ a)
    (reduce .- (concat (list a) args))))

(defn * [& args]
  (if (empty? args)
    1
    (reduce .* args)))

(defn / [a & args]
  (reduce ./ (concat (list a) args)))

(defn require [lib]
  (.require Kernel lib))

(defn range [from til]
  ; XXX this will blow so many stacks
  (if (= from til)
    Rouge.Seq.Empty
    (cons from (range (+ 1 from) til))))

(defn seq? [object]
  (or (= (class object) Rouge.Seq.Cons)
      (= object Rouge.Seq.Empty)))

(def *ns* 'user) ; XXX what

(defn ns-publics [ns]
  )

(defn nth [coll index]
  (.[] (seq coll) index))

(defn first [coll]
  (let [s (seq coll)]
    (and s
         (.first s))))

(defn rest [coll]
  (let [s (seq coll)]
    (if s
      (.more s)
      ())))

(defn next [coll]
  (let [s (seq coll)]
    (and s
         (.next s))))

(defn second [coll]
  (first (next coll)))

(defn > [a b]
  (.> a b))

(defn < [a b]
  (.< a b))

(defmacro macroexpand [form]
  `(.compile Rouge.Compiler (.ns (context)) (Set.) ~form))

(defn push-thread-bindings [map]
  (.push Rouge.Var map))

(defn pop-thread-bindings []
  (.pop Rouge.Var))

(defn hash-map [& keyvals]
  (apply .[] Hash keyvals))

(defmacro binding [bindings & body]
  (let [var-ize (fn [var-vals]
                  (.flatten
                    (.to_a
                      (map
                        (fn [pair]
                          (let [[key val] pair]
                            [`(.name (var ~key)) val]))
                        (.each_slice var-vals 2)))
                    1))]
  `(try
     (push-thread-bindings (hash-map ~@(var-ize bindings)))
     ~@body
     (finally
       (pop-thread-bindings)))))

(defn deref [derefable]
  (.deref derefable))

(defn atom [initial]
  (Rouge.Atom. initial))

(defn swap! [atom f & args]
  (apply .swap! atom f args))

(defn reset! [atom v]
  (.reset! atom v))

(defn quot [n1 n2]
  "Quotient of dividing n1 by n2."
  (.div n1 n2))

(defn rem [n1 n2]
  "Remainder of dividing n1 by n2."
  (.remainder n1 n2))

(defn mod [n1 n2]
  "Modulus of n1 and n2."
  (.modulo n1 n2))

(defn inc [n]
  "Returns one greater than n."
  (+ n 1))

(defn dec [n]
  "Returns one less than n."
  (- n 1))

(defn max [x & more]
  "Returns the greatest value of a set of values."
  (reduce #(if (> %1 %2) %1 %2) (apply vector x more)))

(defn min [x & more]
  "Returns the least value of a set of values."
  (reduce #(if (< %1 %2) %1 %2) (apply vector x more)))

(defn zero? [n]
  "Returns true if n is zero, otherwise false."
  (.zero? n))

(defn pos? [n]
  "Returns true if n is positive, otherwise false."
  (.> n 0))

(defn neg? [n]
  "Returns true if n is negative, otherwise false."
  (.> 0 n))

(defn odd? [n]
  "Returns true if n is odd, otherwise false."
  (.odd? n))

(defn even? [n]
  "Returns true if n is even, otherwise false."
  (.even? n))

(defn number? [n]
  (.is_a? n Numeric))

(defn integer? [n]
  "Returns true if n is an integer."
  (.is_a? n Integer))

(defn float? [n]
  "Returns true if n is a floating point number."
  (.is_a? n Float))

(defn complex? [n]
  "Returns true if n is a complex number."
  (.is_a? n Complex))

(defn rational? [n]
  "Returns true if n is a rational number."
  (or (.is_a? n Rational)
      (.is_a? n Integer)))

(defn bit-and [n1 n2]
  "Bitwise and."
  (if (and (integer? n1) (integer? n2))
    (.& n1 n2)
    (let [msg (str "bit operation not supported for "
                   (class (or (and (not (integer? n1)) n1)
                              (and (not (integer? n2)) n2))))]
      (throw (ArgumentError. msg)))))

(defn bit-or [n1 n2]
  "Bitwise or."
  (if (and (integer? n1) (integer? n2))
    (.| n1 n2)
    (let [msg (str "bit operation not supported for "
                   (class (or (and (not (integer? n1)) n1)
                              (and (not (integer? n2)) n2))))]
      (throw (ArgumentError. msg)))))

(defn bit-xor [n1 n2]
  "Bitwise exclusive or."
  (.send n1 (.to_sym "^") n2))

(defn bit-not [n]
  "Bitwise complement."
  (.send n (.to_sym "~")))

(defn bit-shift-left [n1 n2]
  "Bitwise shift left."
  (if (and (integer? n1) (integer? n2))
    (.<< n1 n2)
    (let [msg (str "bit operation not supported for "
                   (class (or (and (not (integer? n1)) n1)
                              (and (not (integer? n2)) n2))))]
      (throw (ArgumentError. msg)))))

(defn bit-shift-right [n1 n2]
  "Bitwise shift right."
  (if (and (integer? n1) (integer? n2))
    (.>> n1 n2)
    (let [msg (str "bit operation not supported for "
                   (class (or (and (not (integer? n1)) n1)
                              (and (not (integer? n2)) n2))))]
      (throw (ArgumentError. msg)))))

(defn conj [coll & xs]
  ; only cons and vector.  Also SUCKS.
  (if (= 0 (count xs))
    coll
    (let [c (class coll)
          [hd & tl] xs]
      (if (= c Rouge.Seq.Cons)
        (apply conj (Rouge.Seq.Cons coll hd) tl)
        (apply conj (.push (.dup coll) hd) tl)))))

(defn get [map key] ; and [map key not-found]
  (.[] map key))

(defn meta [x]
  ; TODO
  nil)

(defn with-meta [x m]
  ; TODO
  x)

(defmacro .
  [recv method & args]
  `(.send ~recv ~(.name method) ~@args))

(defmacro ->
  ; (-> x) => x
  ([x] x)
  ; (-> e (a b)) => (a e b)
  ; (-> e a) => (a e)
  ([x f]
   (if (seq? f)
     `(~(first f) ~x ~@(rest f))
     `(~f ~x)))
  ([x f & rest]
   `(-> (-> ~x ~f) ~@rest)))

(defn re-pattern [s]
  (.compile Regexp s))

(ns rouge.test
  (:use rouge.core ruby))

(def ^:dynamic *test-level* [])
(def *tests-passed* (atom 0))
(def *tests-failed* (atom []))

(defmacro testing [what & tests]
  `(do
     (when (= [] *test-level*)
       (puts))
     (puts (* " " (count *test-level*) 2) "testing: " ~what)
     (binding [*test-level* (conj *test-level* ~what)]
       ~@tests
       {:passed @*tests-passed*
        :failed @*tests-failed*})))

(defn format-actual [check]
  (if (and (seq? check)
           (= (first check) 'not)
           (= (count check) 2))
    (second check)
    `(not ~check)))

(defmacro is [check]
  `(let [result# (try
                  {:error nil, :result ~check}
                  (catch Exception e#
                    {:error e#, :result false}))]
     (if (not (get result# :result))
      (do
        (swap! *tests-failed* conj (conj *test-level* (pr-str '~check)))
        (puts "FAIL in ???")
        (puts "expected: " ~(pr-str check))
        (let [actual#
                (let [error# (get result# :error)]
                  (if error#
                    error#
                    (format-actual '~check)))]
          (puts "  actual: " (pr-str actual#))))
      (do
        (swap! *tests-passed* inc)
        true))))

(defmacro pending [& body]
  (puts "TODO rouge.test/pending"))

; vim: set ft=clojure cc=80:
