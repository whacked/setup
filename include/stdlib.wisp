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

(defn range [end]
  (let [rtn []]
    (loop [i 0]
      (if (< i end)
        (do
          (.push rtn i)
          (recur (+ 1 i)))))
    rtn))

(defn map [mapfn coll]
  (let [rtn []]
    (.forEach
     coll
     (fn [val]
       (.push rtn (mapfn val))))
    rtn))

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
  (let [out []]
    (loop [i 0]
      (let [part (.slice coll i (+ i partition-size))]
        (if (== partition-size (get part "length"))
          (do
            (.push out part)
            (recur (+ i partition-size)))
          out)))))

(defn rand-nth [coll]
  (aget coll (Math.floor (* (Math.random) coll.length))))
