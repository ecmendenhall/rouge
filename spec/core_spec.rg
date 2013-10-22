;; -*- mode: clojure; -*-

(ns ^{:doc "Spec tests for the Rouge core."
      :author "Amelia Cuss"}
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
  (is (.== false (= () nil))))

(testing "seq"
  (is (.nil? (seq ())))
  (is (.nil? (seq nil)))
  (is (.nil? (seq [])))
  (is (.nil? (seq ""))))

(testing "first"
  (is (.nil? (first nil)))
  (is (.nil? (first ()))))

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

(testing "*command-line-args*"
  (is (= (class *command-line-args*)
         ruby/Array)))
; vim: set ft=clojure:
