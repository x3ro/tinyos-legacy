;; The usual test application: count to the leds
(define i 0)      ; declare i
(settimer0 10)    ; start timer
(define (timer0)  ; timer handler: increment i, set the LEDs
  (set! i (+ i 1))
  (led (& i 7)))
