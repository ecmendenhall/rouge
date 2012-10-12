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
    (is (= (apply list (range 1 51)) (.to_a (ruby/Range. 1 50))))))

(testing "sequential"
  (is (sequential? []))
  (is (sequential? [1]))
  (is (sequential? ()))
  (is (sequential? '(1)))
  (is (not (sequential? nil))))

(testing "="
  (is (.== false (= () nil))))

(testing "seq"
  (is (.== (seq ()) nil))
  (is (.== (seq nil) nil)))

(testing "nth"
  (is (= 1 (nth [1 2 3] 0)))
  (is (= 2 (nth [1 2 3] 1)))
  (is (= 3 (nth [1 2 3] 2))))

#_(testing "macroexpand"
  (is (= 6 (let [f #(* % 2)]
             (do
               (defmacro a [x] `(f ~x))
               (macroexpand '(a 3)))))))

#_(testing "var passing"
  (is (= #'my-var (do
                    (def my-var 4)
                    (let [take-var (fn [v] v)]
                      (take-var #'my-var))))))

#_(testing "for")

; vim: set ft=clojure:
