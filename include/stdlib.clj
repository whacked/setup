(ns stdlib
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [babashka.pods :as pods]
            [hiccup2.core :as h])

  (:import java.time.format.DateTimeFormatter
           java.time.ZonedDateTime))


(def formatter (DateTimeFormatter/ofPattern "yyyy-MM-dd HH:mm:ss.SSSXXXXX"))


(defn timestamp-string []
  ;; => "2020-07-18 18:04:04"
  (.format (ZonedDateTime/now) formatter))

(defn ->html [hiccup]
  (str (h/html {:escape-strings? false} hiccup)))
