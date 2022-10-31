(ns stdlib
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.pods :as pods]
            [hiccup2.core :as h]))

(defn ->html [hiccup]
  (str (h/html {:escape-strings? false} hiccup)))
