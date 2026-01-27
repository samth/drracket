#lang racket/base

(module+ test
  (module config info
    (define lock-name "x-server")))

(require "private/drracket-test-util.rkt"
         racket/class
         framework)

(define (main)
  (fire-up-drracket-and-run-tests
   (λ ()
     (define drs (wait-for-drracket-frame))
     (set-module-language!)
     (do-execute drs)
     (queue-callback/res (λ ()
                           (preferences:set 'framework:coloring-active #f)
                           (handler:edit-file (collection-file-path "map.rkt" "racket" "private"))))
     
     (click-check-syntax-and-check-errors drs "syncheck-eval-compile-time.rkt"))))


;; copied from syncheck-test.rkt ....
(define (click-check-syntax-and-check-errors drs test)
  (click-check-syntax-button drs)
  (wait-for-computation drs)
  (when (queue-callback/res (λ () (send (send drs get-definitions-text) in-edit-sequence?)))
    (error 'syncheck-test.rkt "still in edit sequence for ~s" test))
  
  (define err (queue-callback/res (λ () (send drs syncheck:get-error-report-contents))))
  (when err
    (eprintf "FAILED ~s\n   error report window is visible:\n   ~a\n" test err)))
(define (click-check-syntax-button drs)
  (test:run-one (lambda () (send (send drs syncheck:get-button) command))))

(main)
