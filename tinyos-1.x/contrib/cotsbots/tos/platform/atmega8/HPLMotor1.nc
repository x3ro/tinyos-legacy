/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Sarah Bergbreiter
 * Date last modified:  7/9/02
 *
 */

// The hardware presentation layer for ATmega8L. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component
module HPLMotor1 {
  provides interface HPLMotor;
}
implementation
{

  enum {
    MOTOR_FORWARD = 1,
    MOTOR_REVERSE = 0,
    MOTOR_OFF = 0
  };

  /* NOTE: The Timer1 Hardware Interrupt is handled in HPLMZServoM.td */

  command result_t HPLMotor.init() {
    // Set motor pin directions
    TOSH_CLR_MOTOR1PWM_PIN(); // Motor1 PWM
    TOSH_CLR_MOTOR1DIR_PIN(); // Motor1 Initialized to forward direction

    // Do one bit at a time to not overwrite other things that may be set
    sbi(TCCR1A, COM1A1); // COM1A1 = 1
    cbi(TCCR1A, COM1A0); // COM1A0 = 0
    sbi(TCCR1A, WGM10);  // Phase correct, 8-bit, fixed TOP
    cbi(TCCR1A, WGM11); 
    cbi(TCCR1B, WGM12);
    cbi(TCCR1B, WGM13);

    cbi(TCCR1B, CS12);   // Set prescaler to CK/8
    sbi(TCCR1B, CS11);
    cbi(TCCR1B, CS10);

    // Initialize OCR1AH/L registers
    outp(MOTOR_OFF, OCR1AL);
    // Currently not setting any interrupts for motors

    return SUCCESS;
  }

  command result_t HPLMotor.setSpeed(uint8_t speed) {
    // Set the duty cycle for the PWM output to modulate the speed of motor1.
    if (speed > 250)
    speed = 250;
    outp(speed, OCR1AL);
    return SUCCESS;
  }

  command uint8_t HPLMotor.getSpeed() {
    return inp(OCR1AL);
  }

  command result_t HPLMotor.setDir(uint8_t direction) {
    // Change to non-inverting for forward, inverting for reverse
    if (direction == MOTOR_FORWARD) {
      TOSH_CLR_MOTOR1DIR_PIN();
      cbi(TCCR1A, COM1A0);
    } else {
      TOSH_SET_MOTOR1DIR_PIN();
      sbi(TCCR1A, COM1A0);
    }

    return SUCCESS;
  }

  command uint8_t HPLMotor.getDir() {
    return (TOSH_READ_MOTOR1DIR_PIN() ^ 0x01);
  }
}
