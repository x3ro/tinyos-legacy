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
 * Date last modified:  9/12/02
 *
 */

module HPLAccelM {
  provides interface MotorAccel;
  uses {
    interface ADC as AccelX;
    interface ADCControl as XControl;
    interface ADC as AccelY;
    interface ADCControl as YControl;
  }
}
implementation {

  uint16_t xData;
  uint16_t yData;

  command result_t MotorAccel.init() {
    outp(0x05,TCCR2);   // Set prescaler CK/128 -> overflow at 60Hz
    return rcombine((call XControl.init()),(call YControl.init()));
    return SUCCESS;
  }

  command result_t MotorAccel.startSensing() {
    sbi(TIMSK, TOIE2);
    return SUCCESS;
  }

  command result_t MotorAccel.stopSensing() {
    cbi(TIMSK, TOIE2);
    return SUCCESS;
  }

  TOSH_INTERRUPT(SIG_OVERFLOW2) {
    call AccelX.getData();
  }

  event async result_t AccelX.dataReady(uint16_t data) {
    atomic {
      xData = (data >> 1);
    }
    call AccelY.getData();
    return SUCCESS;
  }

  task void fireAccel() {
    uint16_t xd, yd;
    atomic {
      xd = xData;
      yd = yData;
    }
    signal MotorAccel.fire(xd,yd);
  }

  event async result_t AccelY.dataReady(uint16_t data) {
    atomic {
      yData = data >> 1;
    }
    post fireAccel();
    return SUCCESS;
  }


}
