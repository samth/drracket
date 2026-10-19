#lang racket/base
;; Tests that, with "Run program in separate process", values printed in the
;; interactions window appear before an error raised after them. The
;; interaction is a case from module-lang-test-cases.rkt that failed
;; intermittently on DrDr in separate-process mode; it runs many times here.
(require "private/drracket-test-util.rkt"
         framework
         racket/class)

(define interaction "1 2 (lambda ()) 3 4")
(define expected #rx"^1\n2\n[^\n]*lambda: bad syntax")
(define interactions 4000)
(define interactions-per-run 250)

(fire-up-drracket-and-run-tests
 (λ ()
   (define drs (wait-for-drracket-frame))
   (define interactions-text (queue-callback/res (λ () (send drs get-interactions-text))))

   (set-module-language! #f)
   (test:set-check-box! #rx"Run program in separate process" #t)
   (let ([f (queue-callback/res (λ () (test:get-active-top-level-window)))])
     (test:button-push "OK")
     (wait-for-new-frame f))
   (clear-definitions drs)
   (insert-in-definitions drs "#lang racket/base")

   ;; the output of one interaction: the text between the input and the
   ;; next prompt
   (define (run-interaction)
     (insert-in-interactions drs interaction)
     (define start
       (queue-callback/res
        (λ ()
          (+ (send interactions-text position-paragraph (send interactions-text last-position)) 1))))
     (alt-return-in-interactions drs)
     (wait-for-computation drs)
     (queue-callback/res
      (λ ()
        (define end
          (- (send interactions-text position-paragraph (send interactions-text last-position)) 1))
        (send interactions-text get-text
              (send interactions-text paragraph-start-position start)
              (send interactions-text paragraph-end-position end)))))

   (define wrong
     (for/fold ([wrong '()]) ([i (in-range interactions)])
       (when (zero? (modulo i interactions-per-run))
         (do-execute drs))
       (define output (run-interaction))
       (if (regexp-match? expected output)
           wrong
           (cons output wrong))))

   (unless (null? wrong)
     (eprintf "~a of ~a interactions printed output out of order; for example:\n  ~s\n"
              (length wrong)
              interactions
              (car wrong)))))
