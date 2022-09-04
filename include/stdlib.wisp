(defn identity [x]
  x)
(defn eq [a b]
  (identical? a b))
(defn inc [x]
  (+ x 1))
(defn dec [x]
  (- x 1))

(defn first [coll]
  (aget coll 0))
(defn last [coll]
  (aget coll (- coll.length 1)))
(defn contains?
  [coll key]
  (< -1 (.indexOf coll key)))

(defn sequential? [o]
  (Array.isArray o))

(defn string? [s]
  (== "string" (typeof s)))

(defn map? [o]
  (and (== (typeof o) "object")
       (not (sequential? o))))

(defn range [end]
  (let [rtn []]
    (loop [i 0]
      (if (< i end)
        (do
          (.push rtn i)
          (recur (+ 1 i)))))
    rtn))

(defn -clone [collection]
  (cond (sequential? collection)
        (.slice collection)

        (map? collection)
        (Object.assign {} collection)))

(defn conj [collection & addends]
  (cond (sequential? collection)
        (let [out (-clone collection)]
          (.apply (get out "push") out addends)
          out)))

(defn -ensure-iterable [coll]
  (if (string? coll)
    (.split coll "")
    coll))

(defn map [mapfn & coll]
  (let [arg-sets (.map coll -ensure-iterable)
        max-length (apply Math.min (.map coll (fn [x] (get x "length"))))
        out []]
    (loop [i 0]
      (if (== i max-length)
        out
        (let [arg-set (.map arg-sets
                            (fn [arg-set] (get arg-set i)))]
          (.push out (apply mapfn arg-set))
          (recur (inc i)))))))

(defn vector [& args]
  args)

(defn nth [coll idx]
  (get coll idx))

(defn reduce
  [reducer argv]
  ((aget argv "reduce")
   reducer))

(defn rest [coll]
  (.slice coll 1))

(defn get-in [x access]
  (loop [drill x
         remain access]
    (if (< 0 (aget remain "length"))
      (recur (aget drill (aget remain 0))
             (rest remain))
      drill)))

(defn partition [partition-size coll]
  (let [out []
        iterable-coll (-ensure-iterable coll)]
    (loop [i 0]
      (let [part (.slice iterable-coll i (+ i partition-size))]
        (if (== partition-size (get part "length"))
          (do
            (.push out part)
            (recur (+ i partition-size)))
          out)))))

(defn rand-nth [coll]
  (aget coll (Math.floor (* (Math.random) coll.length))))

(defn into [coll items]
  ;; ONLY these usages now:
  ;; (into {:z 3} [[:a 1] [:b 2]])  --> {:z 3 :a 1 :b 2}
  ;; (into [:z] [[:a 1] [:b 2]])  --> [:z [:a 1] [:b 2]]
  
  (let [out (-clone coll)]
    (cond (sequential? coll)
          (.concat out items)

          (map? coll)
          ;; merge map case, NOT SUPPORTED NOW
          ;; (loop [remain-keys (Object.keys coll)]
          ;;   (if (== 0 (get remain-keys "length"))
          ;;     out
          ;;     (let [key (first remain-keys)
          ;;           value (get items key)])))
          (loop [i 0]
            (if (== i (get items "length"))
              out
              (let [pair (get items i)
                    key (first pair)
                    value (last pair)]
                (aset out key value)
                (recur (inc i))))))))
