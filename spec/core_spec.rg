;; -*- mode: clojure; -*-

(ns ^{:doc "Spec tests for the Rouge core."
      :author "Yuki Izumi"}
  spec.rouge.core
  (:use rouge.test))

(testing "list"
  (testing "empty list creation"
    (is (= (list) '())))
  (testing "unary list creation"
    (is (= (list "trent") '("trent")))
    (is (= (list true) '(true))))
  (testing "n-ary list creation"
    (is (= (apply list (range 1 6)) (.to_a (ruby/Range. 1 5))))))

(testing "or"
  (is (let [q (atom 0)]
        (or 1 (swap! q inc))
        (= @q 0))))

(testing "and"
  (is (let [q (atom 0)]
        (and nil (swap! q inc))
        (= @q 0))))

(testing "sequential"
  (is (sequential? []))
  (is (sequential? [1]))
  (is (sequential? ()))
  (is (sequential? '(1)))
  (is (not (sequential? nil))))

(testing "="
  (is (.== false (= () nil)))
  (is (.== true (= 1)))
  (is (.== true (= 1 1)))
  (is (.== false (= 1 2)))
  (is (.== true (= 1 1 1)))
  (is (.== true (= 1 1 1 1)))
  (is (.== true (= 1 1 1 1 1)))
  (is (.== false (= 1 1 2)))
  (is (.== false (= 1 2 1)))
  (is (.== false (= 2 1 1))))

(testing ">"
  (is (= true (> 1)))
  (is (= false (> 1 1)))
  (is (= true (> 2 1)))
  (is (= true (> 3 2 1)))
  (is (= true (> 5 4 3 2 1 0)))
  (is (= false (> 2 3 1)))
  (is (= false (> 4 5 3 2 1 0))))

(testing ">="
  (is (= true (>= 1)))
  (is (= true (>= 1 1)))
  (is (= true (>= 2 1)))
  (is (= true (>= 3 2 1)))
  (is (= true (>= 5 4 3 2 1 0)))
  (is (= false (>= 2 3 1)))
  (is (= true (>= 3 3 3)))
  (is (= false (>= 5 4 3 2 0 1))))

(testing "<="
  (is (= true (<= 1)))
  (is (= true (<= 1 1)))
  (is (= true (<= 1 2)))
  (is (= true (<= 1 2 3)))
  (is (= true (<= 0 1 2 3 4 5)))
  (is (= false (<= 1 3 2)))
  (is (= true (<= 3 3 3)))
  (is (= false (<= 0 1 2 3 5 4))))

(testing "<"
  (is (= true (< 1)))
  (is (= false (< 1 1)))
  (is (= true (< 1 2)))
  (is (= true (< 1 2 3)))
  (is (= false (< 1 3 2))))

(testing "rand"
  (is (#(and (>= % 0) (< % 1)) (rand)))
  (is (#(and (>= % 0) (< % 10)) (rand 10))))

(testing "rand-int"
  (is (#(and (>= % 0)
             (< % 10)
             (.is_a? % Integer))
             (rand-int 10))))

(testing "subs"
  (is (= "Sad World" (subs "Sick Sad World" 5)))
  (is (= "Sick" (subs "Sick Sad World" 0 4))))

(testing "string?"
  (is (string? "Sick Sad World"))
  (is (= false (string? 12345))))

(testing "symbol?"
  (is (symbol? 'wat))
  (is (= false (symbol? "wat"))))

(testing "keyword?"
  (is (keyword? :wat))
  (is (= false (keyword? 'wat))))

;; XXX How should Rouge handle chars?
;; user=> (map .class (seq "wut"))
;; (ruby/String ruby/String ruby/String)

(testing "not="
  (is (= false (not= 1)))
  (is (not= 1 2))
  (is (= false (not= 1 1 1 1))))

(testing "take"
  (is (= '(0 1 2) (take 3 (range 10)))))

(testing "drop"
  (is (= '(6 7 8) (take 3 (drop 5 (range 1 11))))))

(testing "repeat"
  (is (= '(5 5 5) (take 3 (repeat 5))))
  (is (= '(:a :a :a) (repeat 3 :a))))

(testing "identity"
  (is (= "pretty boring!" (identity "pretty boring!"))))

(testing "constantly"
  (let [always-lol (constantly "lol")]
    (is (= "lol" (always-lol 1)))
    (is (= "lol" (always-lol :a :b)))
    (is (= "lol" (always-lol "tro" "lo" "lo" "lo" "lo")))))

(testing "keys"
  (let [nested-map {:a 1 :b 2 :c {:d 3}}]
    (is (= '(:a :b :c) (keys nested-map)))))

(testing "vals"
  (let [nested-map {:a 1 :b 2 :c {:d 3}}]
    (is (= '(1 2 {:d 3}) (vals nested-map)))))

(testing "complement"
  (let [three? (fn [x] (= 3 x))
        not-three? (complement three?)]
  (is (= true (not-three? 4)))
  (is (= false (not-three? 3)))))

(testing "every?"
  (is (= true (every? even? [])))
  (is (= false (every? even? [1])))
  (is (= true (every? even? [2])))
  (is (= true (every? even? [2 4 6 8 10])))
  (is (= false (every? even? [2 4 6 8 9]))))

(testing "interleave"
  (is (= '(1 6 2 7 3 8 4 9 5 0)
         (interleave [1 2 3 4 5] [6 7 8 9 0]))))

(testing "seq"
  (is (.nil? (seq ())))
  (is (.nil? (seq nil)))
  (is (.nil? (seq [])))
  (is (.nil? (seq ""))))

(testing "first"
  (is (= 1 (first [1])))
  (is (.nil? (first nil)))
  (is (.nil? (first ()))))

(testing "ffirst"
  (is (= 1 (ffirst [[1 2]])))
  (is (.nil? (ffirst ()))))

(testing "rest"
  (is (.== (rest nil) ()))
  (is (.== (rest ()) ())))

(testing "next"
  (is (.nil? (next nil)))
  (is (.nil? (next ()))))

(testing "nth"
  (is (= 1 (nth [1 2 3] 0)))
  (is (= 2 (nth [1 2 3] 1)))
  (is (= 3 (nth [1 2 3] 2))))

(defmacro sample-1 [f] `(do ~f))
(defmacro sample-2 [f] `(do ~@f ~@f))

(testing "macroexpand"
  (is (= '(do x) (macroexpand '(sample-1 x))))
  (is (= '(do x y x y) (macroexpand '(sample-2 (x y))))))

(testing "."
  (is (= '(.send 1 :y 2) (macroexpand '(. 1 y 2)))))

#_(testing "var passing"
  (is (= #'my-var (do
                    (def my-var 4)
                    (let [take-var (fn [v] v)]
                      (take-var #'my-var))))))

#_(testing "for")

(testing "the -> macro"
  (is (= 3 (macroexpand '(-> 3))))
  (is (= '(:x 3) (macroexpand '(-> 3 :x))))
  (is (= '(:y 3 2) (macroexpand '(-> 3 (:y 2)))))
  (is (= '(:z (:y 3 2)) (macroexpand '(-> 3 (:y 2) :z))))
  (is (= '(:z (:y 3 2) 8 9) (macroexpand '(-> 3 (:y 2) (:z 8 9)))))

  (pending
    ; this fails -- it compiles the inc ref.
    (is (= '(inc 3) (macroexpand '(-> 3 inc))))
    ; this fails too -- something weird.
    (is (= '('inc 3) (macroexpand '(-> 3 'inc))))))

(testing "map"
  (is (= Rouge.Seq.Lazy (class (map inc [1 2 3]))))
  (is (= '(2 3 4) (map inc [1 2 3])))
  (is (= '("A" "B" "C") (map .upcase "abc")))
  (is (= 1
         (let [q (atom 0)
               lazy (map #(do (swap! q inc) (inc %)) [1 2 3])]
           (first lazy)
           @q)))
  (is (= 1
         (let [q (atom 0)
               lazy (map #(do (swap! q inc) (inc %)) [1 2 3])]
           (first lazy)
           (first lazy)
           @q)))
  (is (= 2
         (let [q (atom 0)
               lazy (map #(do (swap! q inc) (inc %)) [1 2 3])]
           (first (next lazy))
           @q)))
  (is (= 3
         (let [q (atom 0)
               lazy (map #(do (swap! q inc) (inc %)) [1 2 3])]
           (first (next (next lazy)))
           @q)))
  (is (= 3
         (let [q (atom 0)
               lazy (map #(do (swap! q inc) (inc %)) [1 2 3])]
           (first (next (next (next lazy))))
           @q)))

  (testing "in destructuring"
      (is (= 2
             (let [q (atom 0)
                   [hd & tl] (map #(do (swap! q inc) (inc %)) [1 2 3])]
               @q)))))

(testing "cond"
  (is (= 1 (cond
             :else 1)))
  (is (= 1 (cond
             false 2
             nil 3
             true 1)))
  (is (nil? (cond)))
  (is (nil? (cond
              false 1
              nil 2)))
  (is (= 1 (let [q (atom 0)]
             (is (= :ok (cond
                          (swap! q inc) :ok
                          (swap! q inc) :bad
                          (swap! q inc) :very_bad)))
             @q)))
  (is (= 2 (let [q (atom 0)]
             (is (= :ok (cond
                          (do
                            (swap! q inc)
                            nil) :bad
                          (swap! q inc) :ok
                          (swap! q inc) :very_bad)))
             @q))))

(testing "partial"
  (is (= 11 ((partial + 10) 1)))
  (is (= 21 ((partial + 10 10) 1)))
  (is (= 51 ((partial + 10 10 10 10 10) 1))))

(testing "concat"
  ;; XXX In Clojure, the following three expressions
  ;; evaluate to the empty seq.
  (is (= nil (concat)))
  (is (= nil (concat [])))
  (is (= nil (concat [] [])))

  (is (= (seq [1]) (concat [1] [])))
  (is (= (seq [1]) (concat [] [1])))
  (is (= (seq [1 2]) (concat [1] [2])))
  (is (= (seq [1 2 3 4]) (concat [1 2] [3 4])))
  (is (= (seq [1 2 3 4 5 6 7 8 9 0])
         (concat [1] [2 3] [4 5 6] [7] [8 9 0]))))

(testing "when"
  (is (= nil (when true)))
  (is (= nil (when false)))
  (is (= nil (when false :truthy)))
  (is (= :truthy (when true :truthy))))

(testing "vector"
  (is (= [] (vector)))
  (is (= [1] (vector 1)))
  (is (= [1 2 3 4 5]
         (vector 1 2 3 4 5))))

(testing "vec"
  (is (= [] (vec [])))
  (is (= [1] (vec '(1))))
  (is (= [1 2 3 4 5]
         (vec '(1 2 3 4 5))))

  ;; XXX Converting a Rouge set to a vector
  ;; returns elements in order. Order isn't
  ;; guaranteed in Clojure.
  (is (= [1 3 2 5 4]
         (vec #{1 3 2 5 4})))
  (is (= [[:a 1] [:b 2]]
         (vec {:a 1 :b 2}))))

(testing "cons"
  (is (= '(nil) (cons nil nil)))
  (is (= '(nil) (cons nil '())))
  (is (= '(1)   (cons 1 '())))
  (is (= '(())   (cons '() '())))

  ;; XXX Vectors should be seqable.
  ;; (is (= '(nil) (cons nil [])))
  ;; (is (= [1] (cons 1 [])))
  )

(testing "count"
  (is (= 0 (count [])))
  (is (= 1 (count [1])))
  (is (= 10 (count (range 0 10)))))

(testing "range"
  (is (= '(0 1 2 3 4)
         (range 5)))
  (is (= '(5 6 7 8 9)
         (range 5 10)))
  (is (= '(0 2 4 6 8)
         (range 0 10 2))))

(testing "seq?"
  (is (seq? '()))
  (is (seq? '(1 2 3)))
  (is (= false (seq? [])))
  (is (= false (seq? {:a 1 :b 2})))
  (is (= false (seq? #{1 2 3})))
  (is (= false (seq? #(+ % 1))))
  (is (= false (seq? :a)))
  (is (= false (seq? 1)))
  (is (= false (seq? "string")))
  (is (= false (seq? #"regex"))))

(testing "when-let"
  (is (= :body
         (when-let [a true] :body)))
  (is (= nil
         (when-let [a false] :body))))

(testing "*command-line-args*"
  (is (= (class *command-line-args*)
         ruby/Array)))

; vim: set ft=clojure:
