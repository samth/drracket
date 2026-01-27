#lang racket/base

(module+ test
  (module config info
    (define lock-name "x-server")))
(require racket/gui/base)

;; Using `racket/gui/base` installs the right load handler:
(dynamic-require "collapsed.rkt" 0)
