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
 * Date last modified:  8/12/02
 *
 * Uses the ADC to sense current position and Motor2 to drive the motor
 * to the desired position.
 *
 * NOTE: This module uses the Timer1 Overflow Interrupt.
 *
 * 10/2/2003: Removed disable/enable interrupts around the EEPROM write
 * commands in the ServoCalibration implementation.
 *   call Interrupt.disable();
 *   call EEPROM.write(KI_ADDR,Ki);
 *   call Interrupt.enable();
 *
 *
 */

module MZServoM {
  provides {
    interface Servo;
    interface ServoCalibration;
  }
  uses {
    interface HPLMotor as Motor;
    interface ADC;
    interface ADCControl;
    interface EEPROM;
  }
}
implementation {

  uint8_t straight;
  uint8_t Kp;
  uint8_t Ki;
  uint8_t servoReference;
  uint16_t totalError;
  uint16_t count;
  uint8_t debug;
  uint8_t servoControlCnt;
  uint16_t servoData;

  enum {
    KP_ADDR = 10,
    KI_ADDR = 11,
    STRAIGHT_ADDR = 12
  };

  enum {
    MAX_SPEED = 255,
    OFF = 0,
    REVERSE = 0,
    FORWARD = 1
  };

  /* Set straight variable */
  command result_t ServoCalibration.setStraight(uint8_t newStraight) {
    atomic {
      straight = newStraight;
    }
    call EEPROM.write(STRAIGHT_ADDR,straight);
    return SUCCESS;
  }

  /* Set Kp */
  command result_t ServoCalibration.setKp(uint8_t newKp) {
    atomic {
      Kp = newKp;
    }
    call EEPROM.write(KP_ADDR,Kp);
    return SUCCESS;
  }

  /* Set Ki */
  command result_t ServoCalibration.setKi(uint8_t newKi) {
    atomic {
      Ki = newKi;
    }
    call EEPROM.write(KI_ADDR,Ki);
    return SUCCESS;
  }

  /* Get straight variable */
  command uint8_t ServoCalibration.getStraight() {
    return call EEPROM.read(STRAIGHT_ADDR);
  }

  /* Get Kp */
  command uint8_t ServoCalibration.getKp() {
    return call EEPROM.read(KP_ADDR);
  }

  /* Get Ki */
  command uint8_t ServoCalibration.getKi() {
    return call EEPROM.read(KI_ADDR);
  }

  /* Set Debug */
  command result_t ServoCalibration.setDebug(uint8_t state) {
    atomic {
      debug = state;
    }
    return SUCCESS;
  }

  /* Initialize Servo components and enable Timer1 interrupt */
  command result_t Servo.init() {
    call EEPROM.init();

    atomic {
      /* Read constants from EEPROM */
      Kp = call EEPROM.read(KP_ADDR);
      Ki = call EEPROM.read(KI_ADDR);
      straight = call EEPROM.read(STRAIGHT_ADDR);
      
      /* Set default constants */
      sbi(TIMSK,TOIE1);
      if (straight == 255) straight = 48;
      if (Kp == 255) Kp = 96;
      if (Ki == 255) Ki = 4;
      
      servoReference = straight;
      totalError = 0;
      debug = 0;
      servoControlCnt = 0;
    }
    return rcombine(call Motor.init(), call ADCControl.init());
  }

  /* Set the current turn on the servo */
  command result_t Servo.setTurn(uint8_t turn) {
    if (turn > 60) 
      servoReference = straight + 30;
    else 
      servoReference = straight - 30 + turn;
    totalError = 0;
    return SUCCESS;
  }

  task void servoControl() {
    uint16_t iErr = 0;
    uint8_t error;
    uint8_t control;
    uint8_t data;

    atomic {
      data = servoData;
    }

    /* Find error between actual and desired position */
    data = data >> 1;
    if (data > servoReference) {
      error = data - servoReference;
      call Motor.setDir(REVERSE);
    } else {
      error = servoReference - data;
      call Motor.setDir(FORWARD);
    }

    /* Add to integral error */
    atomic {
      totalError += error;
    }

    /* Choose desired speed based on PI portions of control loop */
    if (error > 0) {
      if (Kp < 136) error = (error*Kp) >> 5;
      else error = 255;
      iErr = (totalError*Ki) >> 5;
      if (error+iErr < MAX_SPEED) {
        control = error+iErr;
      } else {
        control = MAX_SPEED;
      }
    } else {
      totalError = 0;
      control = 0;
    }
    call Motor.setSpeed(control);

    if (debug) {
      TOSH_CLR_RED_LED_PIN();
      count++;
      if (count == 3) {
        signal Servo.debug(data);
        count = 0;
      }
    }
  }

  /* PID loop to control Motor2.  Signals an event with sensed position */
  async event result_t ADC.dataReady(uint16_t data) {
    atomic {
      servoData = data;
    }
    post servoControl();
    return SUCCESS;
  }

  /* Sample the ADC at 1/3 rate of motor PWM */
  TOSH_INTERRUPT(SIG_OVERFLOW1) {
    uint8_t sc;
    atomic {
      sc = servoControlCnt;
      servoControlCnt++;
    }
    if (sc == 3) {
      call ADC.getData();
      atomic {
	servoControlCnt = 0;
      }
    }
  }

  /* EEPROM Write is finished */
  async event result_t EEPROM.writeDone() {
    return SUCCESS;
  }

}

