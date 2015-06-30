/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Kamin Whitehouse
 */

includes Registry;

module TestRegistryM {
  provides{
    interface StdControl;
  }
  uses{
    interface Attribute<uint16_t> as Light @registry("Light");
    interface Attribute<location_t> as Location @registry("Location");

    interface Timer;
    interface ADC as Photo;
    interface StdControl as PhotoControl;
    interface StdControl as ADCControl;
    interface IntOutput as IntToLeds;
  }
}
implementation {

  command result_t StdControl.init() {
    call PhotoControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    location_t location;
    location.x = TOS_LOCAL_ADDRESS;
    location.y = TOS_LOCAL_ADDRESS;
    call Location.set(location);
    call PhotoControl.start();
    call Timer.start(TIMER_REPEAT, 1000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call PhotoControl.stop();
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired(){
    dbg(DBG_USR1,"TestRegistry: timer fired\n");
    call Photo.getData();
    return SUCCESS;
  }

  async event result_t Photo.dataReady(uint16_t data){
    dbg(DBG_USR1,"TestRegistry: photo data ready: setting Light: %d\n", data);
    call Light.set(data);
    return SUCCESS;
  }

  event void Light.updated(uint16_t val)  {
    dbg(DBG_USR1,"TestRegistry: Light Updated\n");
    call IntToLeds.output(val);
  }

  event void Location.updated(location_t val)  {
    dbg(DBG_USR1,"TestRegistry: location updated\n");
    call IntToLeds.output(7);
  }

  event result_t IntToLeds.outputComplete(result_t success){
    return SUCCESS;
  }
}

