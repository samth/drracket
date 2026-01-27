#lang racket/base
(require "private/drracket-test-util.rkt"
         "private/repl-test.rkt")
(fire-up-drracket-and-run-tests (λ () (run-test '(raw))))

(module+ test
  (module config info
    (define lock-name "x-server")
    (define timeout 300)))
