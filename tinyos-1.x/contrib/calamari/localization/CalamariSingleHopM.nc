/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Kamin Whitehouse

includes common_structs;
includes polynomial; //these should not be necessary (for declared reflections in ranging)
includes moving_average;//these should not be necessary
includes Localization;
includes Neighborhood;
includes AnchorHood;
includes SomeCmd;


module CalamariSingleHopM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface RssiAttrReflection as RssiRefl;
    interface Neighborhood as AnchorHood;
    interface Localization;
/*    interface LocationAttrReflection as LocationRefl;
    interface DistanceAttrReflection as DistanceRefl;
    interface RssiAttr;
    interface LocationAttr;
    interface DistanceAttr;*/

    interface Leds;
    interface Clock;
  }
}

implementation
{
	uint8_t localizationCount,managementCount;
  task void doLocalization(){
	dbg(DBG_USR2,"CALAMARI : telling localization to calculate location estimate\n");
	call Localization.estimateLocation();
	localizationCount=0;
  }

  task void pushManagementInfo(){
	dbg(DBG_USR3, "CALAMARI: pushing location and rssi\n");
	call AnchorHood.refresh();
	managementCount=0;
  }

  task void pushRangingInfo(){
	dbg(DBG_USR3, "CALAMARI: pushing rssi\n");
	call RssiRefl.push();
  }

  command result_t StdControl.init()
  {
	localizationCount=0;
	managementCount=0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
	post doLocalization();
	post pushManagementInfo();
	return call Clock.setRate(TOS_I1PS, TOS_S1PS);
  }

  command result_t StdControl.stop()
  {
    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
  }

  event result_t Clock.fire()
  {
	if(managementCount==5){
		post pushManagementInfo();
	}
	else if(localizationCount==5){
		post doLocalization();
	}
	else{
		post pushRangingInfo();
		localizationCount++;
		managementCount++;
	}
    return SUCCESS;
  }

  event void RssiRefl.updated( nodeID_t id, ewma_t value ){}

  event void AnchorHood.removingNeighbor( nodeID_t id ){}
  event void AnchorHood.addedNeighbor( nodeID_t id ){}

}















