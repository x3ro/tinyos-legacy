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
includes Hood;
includes Localization;

module TestHoodM {
  provides{
    interface StdControl;
  }
  uses{
    interface Attribute<uint16_t> as Light @registry("Light");
    interface Reflection<uint16_t> as LightRefl @reflection("LightHood","Light");
    interface Reflection<location_t> as LocationRefl @reflection("LightHood","Location");

    interface Hood as LightHood;
    interface Timer as SendLightTimer;
    interface ADC as Photo;
    interface StdControl as PhotoControl;
    interface IntOutput as IntToLeds;
  }
}
implementation {

  uint16_t lightVal;

  command result_t StdControl.init() {
    call PhotoControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call PhotoControl.start();
    call SendLightTimer.start(TIMER_ONE_SHOT, 1000);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call PhotoControl.stop();
    call SendLightTimer.stop();
    return SUCCESS;
  }

  event result_t SendLightTimer.fired(){
    dbg(DBG_USR1, "TestHood: Timer fired\n");
    call Photo.getData();
    return SUCCESS;
  }

  task void setLight(){
    atomic{
      call Light.set(lightVal);
    }
  }
  async event result_t Photo.dataReady(uint16_t data){
    dbg(DBG_USR1, "TestHood: photo data ready\n");
    lightVal = data;
    post setLight();
    return SUCCESS;
  }

  event void Light.updated(uint16_t val)  {
    dbg(DBG_USR1, "TestHood: light updated\n");
    call IntToLeds.output(7);
  }

  event void LightRefl.updated(uint16_t nodeID, uint16_t val)  {
    dbg(DBG_USR1, "TestHood: light reflection updated for node %d\n", nodeID);
    call IntToLeds.output(val);
  }

  event void LocationRefl.updated(uint16_t nodeID, location_t val)  {
    dbg(DBG_USR1, "TestHood: location reflection updated for node %d\n", nodeID);
    call IntToLeds.output(val.x);
  }

  event result_t IntToLeds.outputComplete(result_t success){
    return SUCCESS;
  }

  event void LightHood.addedNeighbor(uint16_t nodeID){
    //to demonstrate queries, we ask for updates of all attributes of
    //new neighbors

    dbg(DBG_USR1, "TestHoodM: received new neighbor: node %d\n", nodeID);

    /***************
     *  These two queries will be sent in a single msg.
     *
     *  If more than two nodes are querying nodeID at the same time,
     *  nodeID will only send a single response message.
     **************/

    dbg(DBG_USR1, "TestHoodM: querying for light and location of node %d\n", nodeID);
    call LightRefl.update(nodeID);
    call LocationRefl.update(nodeID);

    /****************
     *  We could also ask for an update of a node not in the
     *  neighborhood, including TOS_BCAST_ADDR.
     *
     *  This is useful in the current test app, for example, when one
     *  node sends both light and location messages before any of the
     *  other nodes turn on.  By switching the folling two lines for
     *  the previous two, a node queries for any new nodes in the area
     *  each time it adds a new neighbor, so it should also be able to
     *  add nodes that sent their data before it woke up.
     ****************/

    //    dbg(DBG_USR1, "TestHoodM: querying for light and location of all neighbors\n");
    //    call LightRefl.update(TOS_BCAST_ADDR);
    //    call LocationRefl.update(TOS_BCAST_ADDR);

  }

  event void LightHood.removedNeighbor(uint16_t nodeID){
    dbg(DBG_USR1, "TestHoodM: lost neighbor: node %d\n", nodeID);
  }
}

