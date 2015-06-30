//$Id: SounderM.nc,v 1.2 2005/07/06 17:25:14 cssharp Exp $
/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
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
 */

/**
 * Implementation file for the Trio sounder <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;

module SounderM
{
  provides {
    interface StdControl;
    interface Sounder;
  }
  uses {
    interface StdControl as IOSwitch1Control;
    interface IOSwitch as IOSwitch1;
  }
}

implementation
{
  command result_t StdControl.init() {
    call IOSwitch1Control.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IOSwitch1Control.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call IOSwitch1Control.stop();
    return SUCCESS;
  }

  command result_t Sounder.setStatus(bool high) {
    if (high) {
      return call IOSwitch1.setPort0Pin(IOSWITCH1_PW_SOUNDER, FALSE);
    }
    else {
      return call IOSwitch1.setPort0Pin(IOSWITCH1_PW_SOUNDER, TRUE);
    }
  }

  command result_t Sounder.getStatus() {
    call IOSwitch1.getPort();
    return SUCCESS;
  }

  event void IOSwitch1.getPortDone(uint16_t _bits, result_t _success) {
    uint8_t _port0_bits = (uint8_t) (_bits & 0xff);
    if (_port0_bits & IOSWITCH1_PW_SOUNDER) {
      signal Sounder.getStatusDone(FALSE, _success);
    }
    else {
      signal Sounder.getStatusDone(TRUE, _success);
    }
  }

  event void IOSwitch1.setPortDone(result_t result) { }
}

