;; A TinyScheme version of the standard TinyOS OscilloscopeRF application: 
;; collect 10 sensor (light) readings and broadcast them over the radio.

;; The mote on your base station should have id 0, all other nodes should
;; have different, non-zero ids.

;; You can use the java net.tinyos.oscope.oscilloscope application to
;; display these readings if you apply the patch at the end of the
;; oscilloscope.mt file (which should be in the same directory as this
;; file)

;; NOTE: you will want to change the call to (light) below to a sensor
;; included in your VM.

;;;;;; CODE STARTS HERE ;;;;;;

;; The current set of readings. Change samples to collect more or less
;; readings at a time
(define samples 10)
(define current 0)
(define readings (make-vector samples))

;; Start timer0 at 5Hz except on node 0.
(settimer0 (if (zero? (id)) 0 2))

(define (timer0)
  ;; get a reading, and send a message over the radio if the buffer is full
  (vector-set! readings
	       (modulo current samples)
	       (light))
  (set! current (+ current 1))
  (if (zero? (modulo current samples))
      (send-data readings)))

(define (send-data data)
  (led (| l_blink l_yellow))
  ;; encode builds a message (string) from a vector
  ;; by default, each integer becomes 2 bytes
  (send bcast-addr (encode (vector (id) current 0 (encode readings)))))

;; Define receive handler, which forwards received messages to
;; the serial port, only on node 0
(define receive
  (if (zero? (id)) (lambda () (send uart-addr received-msg()))
      '()))
