#lang racket/base

;; Run this file from any directory with the drracket-test package installed.
;; Reuse its save-hash-lang-line test and GUI helpers.
(require racket/gui/base)

(define reader-file
  (collection-file-path "in-irl-namespace.rkt" "drracket" "private"))
(define delayed? #f)
(define failed? #f)
(define original-load (current-load/use-compiled))
(define original-display (error-display-handler))
(define original-exit (exit-handler))

(parameterize
    ([current-load/use-compiled
      (lambda (path mod)
        ;; Dispatch the language-change timer while the first reader load is
        ;; active. A reentrant update must wait for that load to finish.
        (when (and (not delayed?)
                   (equal? (simplify-path path #f) (simplify-path reader-file #f)))
          (set! delayed? #t)
          (sleep/yield 0.6))
        (original-load path mod))]
     [error-display-handler
      (lambda (message exn)
        ;; Include reader errors that DrRacket hides in its error panel.
        (set! failed? #t)
        (original-display message exn))]
     [exit-handler
      (lambda (code)
        (unless delayed?
          (eprintf "did not exercise the initial insulated-reader load\n"))
        (original-exit (if (and delayed? (not failed?)) code 1)))])
  (dynamic-require '(lib "save-hash-lang-line.rkt" "tests" "drracket") #f))
