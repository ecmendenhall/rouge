;; -*- mode: clojure; -*-

(ns ^{:doc "Spec tests for the Rouge core."
      :author "Arlen Christian Mart Cuss"}
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
  (is (.nil? (seq []))))

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


; vim: set ft=clojure:
