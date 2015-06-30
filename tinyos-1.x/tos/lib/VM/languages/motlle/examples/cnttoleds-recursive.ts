;; The usual test application: count to the leds
;; This version relies on tail recursion
(define (ledcount i)
  (led (& i 7))
  (sleep 10)
  (ledcount (+ i 1)))
(ledcount 0)
